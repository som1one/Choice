import {
    View,
    Image,
    Text,
} from 'react-native';
import { Icon } from 'react-native-elements';
import { Callout, Marker } from "react-native-maps";

const ImageMarker = ({imageUri, isMarked}) => {
    return (
        <Image 
            style={{
                width: 40, 
                height: 40,
                borderRadius: 40/2,
                borderWidth: 4,
                borderColor: isMarked ? '#2D81E0' : 'white',
                backgroundColor: 'white'
            }}
            source={{uri: imageUri}}
            />
    );
}

const CustomMarker = ({imageUri, averageGrade, coordinate, onPress, isMarked, isCompany}) => {
    let s = new Number(averageGrade).toString();
    const formattedGrade = s.length == 3 ? s.slice(0, 2) : `${s}.0`;

    return (
        <Marker
            coordinate={coordinate}
            onPress={onPress}>
            <View
                style={{
                    flexDirection: 'column',
                    justifyContent: 'center',
                    alignSelf: 'center'
                }}>
                <ImageMarker
                    imageUri={imageUri}
                    isMarked={isMarked}/>
                {isCompany ? 
                <>
                    <View
                        style={{
                            flexDirection: 'row',
                            alignSelf: 'center',
                            justifyContent: 'center'
                        }}>
                        <Icon
                            size={20}
                            type='material'
                            name='star'
                            color='yellow'
                            style={{
                                alignSelf: 'center'
                            }}/>
                        <Text
                            style={{
                                fontSize: 16,
                                fontWeight: '600',
                                alignSelf: 'center',
                                color: 'black'
                            }}>
                            {formattedGrade}
                        </Text>
                    </View>
                </>
                :
                <>
                </>}
            </View>
        </Marker>
    );
}

export default CustomMarker;