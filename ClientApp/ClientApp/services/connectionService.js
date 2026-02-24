import * as SignalR from '@microsoft/signalr'
import env from '../env';
import 'react-native-url-polyfill/auto';
import {
    DeviceEventEmitter
} from 'react-native';

let builder = new SignalR.HubConnectionBuilder();
let connection = builder.withUrl(`${env.api_url}/chat`).build();

const build = (token) => {

    connection = builder
        .withUrl(`${env.api_url}/chat`, { accessTokenFactory: () => token })
        .build();

    connection.on('orderCreated', message => {
        console.log('Order created');
        DeviceEventEmitter.emit('messageReceived', message);
        DeviceEventEmitter.emit('tabMessageReceived');
    });

    connection.on('send', message => {
        DeviceEventEmitter.emit('messageReceived', message);
        DeviceEventEmitter.emit('tabMessageReceived');
    });

    connection.on('enrollmentDateChanged', message => {
        DeviceEventEmitter.emit('enrollmentDateChanged', message);
        DeviceEventEmitter.emit('tabMessageReceived');
    });

    connection.on('enrolled', message => {
        DeviceEventEmitter.emit('messageChanged', message);
    });

    connection.on('confirmed', message => {
        DeviceEventEmitter.emit('messageChanged', message);
    });

    connection.on("statusChanged", message => {
        DeviceEventEmitter.emit('messageChanged', message)
    });

    connection.on("userStatusChanged", user => {
        DeviceEventEmitter.emit('chatChanged', user);
    });

    connection.on("read", message => {
        DeviceEventEmitter.emit('read', message);
    });

    connection.onclose(async (e) => {
        if (e != undefined) {
            console.log(e.message);
            DeviceEventEmitter.emit('closed');
        }
    });
}

const start = async () => {
    await connection.start();
}

const stop = async () => {
    await connection.stop();
}

export default {
    build,
    start,
    stop
}
