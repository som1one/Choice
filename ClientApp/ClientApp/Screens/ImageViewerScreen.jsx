import React from "react";
import {
    View,
    Image,
    Dimensions,
    TouchableOpacity
} from 'react-native';
import env from "../env";
import { Icon } from "react-native-elements";

const ImageViewerScreen = ({navigation, route}) => {
    const wh = Dimensions.get('screen');

    return (
        <View
            style={{
                flex: 1
            }}>
            <Image
                style={{
                    width: wh.width,
                    height: wh.height
                }}
                source={{uri: `${env.api_url}/api/objects/${route.params.imageUri}`}}/>

            <View
                style={{
                    backgroundColor: '#000000B2',
                    height: wh.height/12,
                    width: wh.width,
                    position: 'absolute',
                    top: 0,
                    flexDirection: 'row',
                    paddingHorizontal: 15,
                    justifyContent: 'flex-start'
                }}>
                <TouchableOpacity
                    style={{
                        alignSelf: 'center'
                    }}
                    onPress={() => navigation.goBack()}>
                    <Icon
                        name='chevron-left'
                        type='material'
                        color='white'
                        size={30}/>
                </TouchableOpacity>
            </View>
        </View>
    )
}

export default ImageViewerScreen