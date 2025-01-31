#include "aohdsystem.h"

#include "../qopenhdmavlinkhelper.hpp"
#include "../../common/StringHelper.hpp"
#include "../../common/TimeHelper.hpp"
#include "../telemetryutil.hpp"
#include "wificard.h"
#include "rcchannelsmodel.h"
#include "camerastreammodel.h"

#include <string>
#include <sstream>

#include <logging/logmessagesmodel.h>
#include <logging/hudlogmessagesmodel.h>

#include "util/qopenhd.h"

AOHDSystem::AOHDSystem(const bool is_air,QObject *parent)
    : QObject{parent},_is_air(is_air)
{
    m_alive_timer = new QTimer(this);
    QObject::connect(m_alive_timer, &QTimer::timeout, this, &AOHDSystem::update_alive);
    m_alive_timer->start(1000);
}

AOHDSystem &AOHDSystem::instanceAir()
{
    static AOHDSystem air(true);
    return air;
}

AOHDSystem &AOHDSystem::instanceGround()
{
    static AOHDSystem ground(false);
    return ground;
}

void AOHDSystem::register_for_qml(QQmlContext *qml_context)
{
    qml_context->setContextProperty("_ohdSystemAir", &AOHDSystem::instanceAir());
    qml_context->setContextProperty("_ohdSystemGround", &AOHDSystem::instanceGround());
}

bool AOHDSystem::process_message(const mavlink_message_t &msg)
{
    if(msg.sysid != get_own_sys_id()){
        qDebug()<<"AOHDSystem::process_message: wron sys id";
        return false;
    }
    m_last_message_ms=QOpenHDMavlinkHelper::getTimeMilliseconds();
    switch(msg.msgid){
        case MAVLINK_MSG_ID_OPENHD_VERSION_MESSAGE:{
            mavlink_openhd_version_message_t parsedMsg;
            mavlink_msg_openhd_version_message_decode(&msg,&parsedMsg);
            QString version(parsedMsg.version);
            set_openhd_version(version);
            return true;
        }break;
        case MAVLINK_MSG_ID_ONBOARD_COMPUTER_STATUS:{
            mavlink_onboard_computer_status_t parsedMsg;
            mavlink_msg_onboard_computer_status_decode(&msg,&parsedMsg);
            process_onboard_computer_status(parsedMsg);
            return true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_MONITOR_MODE_WIFI_CARD:{
            mavlink_openhd_stats_monitor_mode_wifi_card_t parsedMsg;
            mavlink_msg_openhd_stats_monitor_mode_wifi_card_decode(&msg,&parsedMsg);
            //qDebug()<<"Got MAVLINK_MSG_ID_OPENHD_WIFI_CARD"<<(int)parsedMsg.card_index<<" "<<(int)parsedMsg.rx_rssi;
            process_x0(parsedMsg);
            return true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_MONITOR_MODE_WIFI_LINK:{
            mavlink_openhd_stats_monitor_mode_wifi_link_t parsedMsg;
            mavlink_msg_openhd_stats_monitor_mode_wifi_link_decode(&msg,&parsedMsg);
            process_x1(parsedMsg);
            return true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_TELEMETRY:{
            mavlink_openhd_stats_telemetry_t parsedMsg;
            mavlink_msg_openhd_stats_telemetry_decode(&msg,&parsedMsg);
            process_x2(parsedMsg);
            return true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_WB_VIDEO_AIR:{
            mavlink_openhd_stats_wb_video_air_t parsedMsg;
            mavlink_msg_openhd_stats_wb_video_air_decode(&msg,&parsedMsg);
            process_x3(parsedMsg);
            return true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_STATS_WB_VIDEO_GROUND:{
            mavlink_openhd_stats_wb_video_ground_t parsedMsg;
            mavlink_msg_openhd_stats_wb_video_ground_decode(&msg,&parsedMsg);
            process_x4(parsedMsg);
            return true;
        }break;
        case MAVLINK_MSG_ID_OPENHD_ONBOARD_COMPUTER_STATUS_EXTENSION:{
            mavlink_openhd_onboard_computer_status_extension_t parsedMsg;
            mavlink_msg_openhd_onboard_computer_status_extension_decode(&msg,&parsedMsg);
            return true;
        }break;
        case MAVLINK_MSG_ID_HEARTBEAT:{
            mavlink_heartbeat_t parsedMsg;
            mavlink_msg_heartbeat_decode(&msg,&parsedMsg);
            m_last_heartbeat_ms=QOpenHDMavlinkHelper::getTimeMilliseconds();
            if(parsedMsg.autopilot!=MAV_AUTOPILOT_INVALID){
                qDebug()<<"Warning OpenHD systems should always set autopilot to none";
            }
            return true;
        }break;
        case MAVLINK_MSG_ID_RC_CHANNELS_OVERRIDE:{
             mavlink_rc_channels_override_t parsedMsg;
             mavlink_msg_rc_channels_override_decode(&msg,&parsedMsg);
             RCChannelsModel::instanceGround().update_all_channels(Telemetryutil::mavlink_msg_rc_channels_override_to_array(parsedMsg));
             return true;
        };break;
        case MAVLINK_MSG_ID_STATUSTEXT:{
             mavlink_statustext_t parsedMsg;
             mavlink_msg_statustext_decode(&msg,&parsedMsg);
             auto tmp=Telemetryutil::statustext_convert(parsedMsg);
             LogMessagesModel::instanceOHD().addLogMessage(_is_air ? "OHD[A]":"OHD[G]",tmp.message.c_str(),tmp.level);
             // Notify user in HUD of external device connect / disconnect events
             if(tmp.message.find("External device") != std::string::npos){
                HUDLogMessagesModel::instance().add_message(tmp.level,tmp.message.c_str());
             }
             return true;
        }break;
        /*case MAVLINK_MSG_ID_OPENHD_LOG_MESSAGE:{
            mavlink_openhd_log_message_t parsedMsg;
            mavlink_msg_openhd_log_message_decode(&msg,&parsedMsg);
            const QString message{parsedMsg.text};
            const quint64 timestamp=parsedMsg.timestamp;
            const quint8 severity=parsedMsg.severity;
            qDebug()<<"Log message:"<<message;
            LogMessagesModel::instance().addLogMessage({"OHD",message,timestamp,LogMessagesModel::log_severity_to_color(severity)});
            break;
        }*/
    }
    return false;
}

void AOHDSystem::process_onboard_computer_status(const mavlink_onboard_computer_status_t &msg)
{
    set_curr_cpuload_perc(msg.cpu_cores[0]);
    set_curr_soc_temp_degree(msg.temperature_core[0]);
    // temporary, we repurpose this value
    set_curr_cpu_freq_mhz(msg.storage_type[0]);
    set_curr_isp_freq_mhz(msg.storage_type[1]);
    set_curr_h264_freq_mhz(msg.storage_type[2]);
    set_curr_core_freq_mhz(msg.storage_type[3]);
    set_curr_v3d_freq_mhz(msg.storage_usage[0]);
    set_curr_space_left_mb(msg.storage_usage[1]);
    set_ina219_voltage_millivolt(msg.storage_usage[2]);
    set_ina219_current_milliamps(msg.storage_usage[3]);
    set_ram_usage_perc(msg.ram_usage);
    set_ram_total(msg.ram_total);
}

void AOHDSystem::process_x0(const mavlink_openhd_stats_monitor_mode_wifi_card_t &msg){
    if(_is_air && msg.card_index>1){
        qDebug()<<"Air only has 1 wifibroadcats card";
        return;
    }
    //qDebug()<<"Got mavlink_openhd_stats_monitor_mode_wifi_card_t";
    if(_is_air){
        if(msg.card_index!=0){
            qDebug()<<"Air only has 1 wifibroadcats card";
            return;
        }
        auto& card=WiFiCard::instance_air();
        card.set_alive(true);
        card.set_curr_rx_rssi_dbm(msg.rx_rssi);
        card.set_n_received_packets(msg.count_p_received);
        set_current_rx_rssi(msg.rx_rssi);
    }else{
        if(msg.card_index<0 || msg.card_index>=4){
            qDebug()<<"Gnd invalid card index"<<msg.card_index;
            return;
        }
        auto& card=WiFiCard::instance_gnd(msg.card_index);
        card.set_alive(true);
        card.set_curr_rx_rssi_dbm(msg.rx_rssi);
        card.set_n_received_packets(msg.count_p_received);
        set_current_rx_rssi(WiFiCard::helper_get_gnd_curr_best_rssi());
    }
}

void AOHDSystem::process_x1(const mavlink_openhd_stats_monitor_mode_wifi_link_t &msg){
    //qDebug()<<"Got mavlink_openhd_stats_monitor_mode_wifi_link_t";
    set_curr_rx_packet_loss_perc(msg.curr_rx_packet_loss_perc);
    set_count_tx_inj_error_hint(msg.count_tx_inj_error_hint);
    set_count_tx_dropped_packets(msg.count_tx_dropped_packets);
}

void AOHDSystem::process_x2(const mavlink_openhd_stats_telemetry_t &msg)
{
    //qDebug()<<"Got mavlink_openhd_stats_telemetry_t";
    set_curr_telemetry_rx_pps(Telemetryutil::pps_to_string(msg.curr_rx_pps));
    set_curr_telemetry_tx_pps(Telemetryutil::pps_to_string(msg.curr_tx_pps));
    set_curr_telemetry_rx_bps(Telemetryutil::bitrate_bps_to_qstring(msg.curr_rx_bps));
    set_curr_telemetry_tx_bps(Telemetryutil::bitrate_bps_to_qstring(msg.curr_tx_bps));
}

void AOHDSystem::process_x3(const mavlink_openhd_stats_wb_video_air_t &msg){
    //qDebug()<<"Got mavlink_openhd_stats_wb_video_air_t";
    if(!_is_air){
        qDebug()<<"warning got mavlink_openhd_stats_wb_video_air from ground";
        return;
    }
    // We use parts of this message ourself, but mostly, we just forward it to the right CameraStreamModel
    // (it is
    if(msg.link_index==0 || msg.link_index==1){
        auto& cam=CameraStreamModel::instance(msg.link_index);
        cam.update_mavlink_openhd_stats_wb_video_air(msg);
    }
    // dirty
    if(msg.link_index!=0)return;
    if(x_last_dropped_packets<0){
        x_last_dropped_packets=msg.curr_dropped_packets;
    }else{
        const auto delta=msg.curr_dropped_packets-x_last_dropped_packets;
        x_last_dropped_packets=msg.curr_dropped_packets;
        if(delta>0){
            const auto elapsed_since_last=std::chrono::steady_clock::now()-m_last_tx_error_hud_message;
            if(elapsed_since_last>std::chrono::seconds(3)){
                HUDLogMessagesModel::instance().add_message_warning("TX error,reduce bitrate");
                m_last_tx_error_hud_message=std::chrono::steady_clock::now();
            }
            set_tx_is_currently_dropping_packets(true);
        }else{
            set_tx_is_currently_dropping_packets(false);
        }
    }
}

void AOHDSystem::process_x4(const mavlink_openhd_stats_wb_video_ground_t &msg){
    //qDebug()<<"Got mavlink_openhd_stats_wb_video_ground_t";
    if(_is_air){
         qDebug()<<"warning got mavlink_openhd_stats_wb_video_ground from air";
         return;
    }
    if(msg.link_index==0 || msg.link_index==1){
        auto& cam=CameraStreamModel::instance(msg.link_index);
        cam.update_mavlink_openhd_stats_wb_video_ground(msg);
    }
}

void AOHDSystem::update_alive()
{
    if(m_last_heartbeat_ms==-1){
        set_is_alive(false);
    }else{
        const auto elapsed_since_last_heartbeat=QOpenHDMavlinkHelper::getTimeMilliseconds()-m_last_heartbeat_ms;
        // after 3 seconds, consider as "not alive"
        const bool alive=elapsed_since_last_heartbeat< 4*1000;
        if(alive != m_is_alive){
            // message when state changes
            send_message_hud_connection(alive);
            //
            set_is_alive(alive);
        }
    }
    {
        // If we don't get any bitrate updates, after 5 seconds go back to default
        const auto delta=std::chrono::steady_clock::now()-m_last_message_openhd_stats_total_all_wifibroadcast_streams;
        if(delta>std::chrono::seconds(5)){
            //TODO clear curr values
        }
    }
}

bool AOHDSystem::send_command_long(mavsdk::Action::CommandLong command)
{
    if(!_action){
        return false;
    }
    const auto res=_action->send_command_long(command);
    assert(command.target_system_id==get_own_sys_id());
    std::stringstream ss;
    ss<<"Action: "<<res;
    qDebug()<<QString(ss.str().c_str());
    if(res==mavsdk::Action::Result::Success){
        return true;
    }
    return false;
}


void AOHDSystem::set_system(std::shared_ptr<mavsdk::System> system)
{
    // once discovered, the system never changes !
    assert(_system==nullptr);
    assert(system->get_system_id()==get_own_sys_id());
    _system=system;
    _action=std::make_shared<mavsdk::Action>(system);
}

bool AOHDSystem::send_command_reboot(bool reboot)
{
    mavsdk::Action::CommandLong command{};
    command.target_system_id= get_own_sys_id();
    command.target_component_id=0; // unused r.n
    command.command=MAV_CMD_PREFLIGHT_REBOOT_SHUTDOWN;
    command.params.maybe_param1=0;
    command.params.maybe_param2=(reboot ? 1 : 2);
    return send_command_long(command);
}

void AOHDSystem::send_message_hud_connection(bool connected){
    std::stringstream message;
    if(_is_air){
        message << "Air unit ";
    }else{
        message << "Ground unit ";
    }
    if(connected){
        message << "connected";
        HUDLogMessagesModel::instance().add_message_info(message.str().c_str());
        //QOpenHD::instance().textToSpeech_sayMessage(message.str().c_str());
    }else{
        message << "disconnected";
        HUDLogMessagesModel::instance().add_message_warning(message.str().c_str());
    }
}

bool AOHDSystem::should_request_version()
{
    if(m_openhd_version=="N/A" &&  m_n_times_version_has_been_requested<10){
         m_n_times_version_has_been_requested++;
        return true;
    }
    return false;
}

