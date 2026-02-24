import React from 'react';
import {
    View,
    Image,
    TouchableOpacity,
    Dimensions
} from 'react-native';
import { Icon } from 'react-native-elements';
import * as ImagePicker from 'react-native-image-picker';
import RNFS, { read } from 'react-native-fs';
import {toByteArray } from 'react-native-quick-base64';

const ImageBox = ({onUriChanged, uri, readOnly}) => {
    const { width, height } = Dimensions.get('screen');
    readOnly = readOnly == undefined ? false : readOnly;
    const [imageUri, setImageUri] = React.useState(uri);

    const addImage = async () => {
        let response = await ImagePicker.launchImageLibrary();

        if (!response.didCancel) {
            const directories = response.assets[0].uri.split('/')

            const data = await RNFS.readFile(response.assets[0].uri, 'base64');
            const fileNameAndExtension = directories[directories.length-1].split('.');
            const buffer = toByteArray(data);

            if ((fileNameAndExtension[1] == 'png' || fileNameAndExtension[1] == 'jpg') && buffer.length <= 150000) {
                setImageUri(response.assets[0].uri);
                onUriChanged(response.assets[0].uri);
            }
            else {
                console.log(`Size: ${buffer.length} || Extension: ${fileNameAndExtension[1]}`);
            }
        }
    }

    const removeImage = () => {
        setImageUri('');
        onUriChanged('');
    }

    return (
        <View>
            {
                imageUri == '' ?
                <>
                    <View 
                        style={{
                            width: width/3.8, 
                            height: width/3.8, 
                            backgroundColor: readOnly ? 'transparent' : '#F9F9F9', 
                            borderWidth: 2, 
                            borderRadius: 8, 
                            borderStyle: 'dashed', 
                            borderColor: readOnly ? 'transparent' : '#C8C8C8', 
                            justifyContent: 'center'
                        }}>
                        <TouchableOpacity 
                            onPress={async () => await addImage()}
                            disabled={readOnly}>
                            <Icon 
                                name='arrow-circle-down'
                                type='material'
                                size={40}
                                color={readOnly ? 'transparent' : '#2D81E0'}/>
                        </TouchableOpacity>
                    </View>
                    </>
                    :
                    <>
                        <View 
                            style={{
                                width: width/3.8+width/(3.8*50),
                                height: width/3.8+width/(3.8*50),
                                borderRadius: 8,
                                borderStyle: 'dashed',
                                borderWidth: readOnly ? 0 : 2,
                                borderColor: 'black',
                                backgroundColor: 'transparent',
                                justifyContent: 'center',
                                position: 'relative'
                            }}>
                            <View 
                                style={{
                                    position: 'absolute',
                                    top: -12,
                                    right: -13,
                                    width: '100%',
                                    alignItems: 'flex-end',
                                    zIndex: 1,
                                }}>
                                {!readOnly ? 
                                <>
                                    <TouchableOpacity
                                        style={{
                                            backgroundColor: 'white',
                                            borderColor: '#E7E7E7',
                                            borderWidth: 2,
                                            borderRadius: 360
                                        }}
                                        onPress={() => removeImage()}>
                                        <Icon 
                                            name='close'
                                            type='material'
                                            size={20}
                                            color={'#818C99'}/>
                                    </TouchableOpacity>
                                </>
                                :
                                <>
                                </>}
                            </View>
                            <Image 
                                style={{
                                width: width/3.8,
                                height: width/3.8,
                                borderRadius: 8,
                                alignSelf: 'center',
                                padding: 10
                            }}
                            source={{uri: imageUri}}/>
                    </View>
                </>
            }
        </View>
    );
}

export default ImageBox;