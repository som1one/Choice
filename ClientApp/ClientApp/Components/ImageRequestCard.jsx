import React from "react";
import {
    View,
    Image,
    Dimensions,
    TouchableOpacity
} from 'react-native';
import env from "../env";

const ImageRequestCard = ({navigation, imageUri}) => {
    const wh = Dimensions.get('screen');

    return (
        <View>
            <TouchableOpacity
                onPress={() => navigation.navigate('ImageViewer', {imageUri})}>
                <Image
                    style={{
                        width: wh.width/4,
                        height: wh.width/4,
                        borderRadius: 15,
                        borderColor: 'gray',
                        borderWidth: 1
                    }}
                    source={{uri: `${env.api_url}/api/objects/${imageUri}`}}/>
            </TouchableOpacity>
        </View>
    );
}

export default ImageRequestCard;