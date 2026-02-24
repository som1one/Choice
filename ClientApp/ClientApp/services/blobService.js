import RNFS from 'react-native-fs';
import {toByteArray } from 'react-native-quick-base64';
import env from '../env';

const uploadImage = async (filePath) => {
    if (filePath == '') {
        return '';
    }

    const directories = filePath.split('/')

    const data = await RNFS.readFile(filePath, 'base64');
    const fileNameAndExtension = directories[directories.length-1].split('.');
    const buffer = toByteArray(data);

    if (buffer.length > 2000000 || (fileNameAndExtension[1] != 'png' && fileNameAndExtension[1] != 'jpg')) {
        return 0;
    }

    const fileName = `${fileNameAndExtension[0]}-${fileNameAndExtension[1]}`;

    return await fetch(`${env.api_url}/api/objects/${fileName}`, {
        method: 'POST',
        body: buffer,
        headers: {
            'Content-Type':'application/octet-stream'
        }
    })
    .then(async response => { 
        console.log(response.status);
        if (response.status == 200) {
            return fileName; 
        }
        else {
            return '';
        }
    });
}

export default {
    uploadImage
}