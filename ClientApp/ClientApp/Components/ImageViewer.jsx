import React from "react"
import {
    View,
    Dimensions,
    Image,
} from 'react-native';
import { FlatList } from "react-native-actions-sheet";

const ImageViewer = ({images}) => {
    const { width, height } = Dimensions.get('screen');
    const [currentIndex, setCurrentIndex] = React.useState(0);
    const ref = React.useRef(null);

    const imagesArray = Object.keys(images).map((i) => ({
        index: i,
        url: images[i]
    }));

    const onViewableItemsChanged = React.useRef(({viewableItems, changed}) => {
        viewableItems.forEach(i => {
            setCurrentIndex(i.item.index);
        });
    });

    const viewabilityConfig = React.useRef({viewAreaCoveragePercentThreshold: 100});

    return (
        <View>
            <View
                style={{
                    height: height/4.5,
                    borderRadius: 20,
                }}
                ref={ref}>
                <FlatList
                    horizontal
                    showsHorizontalScrollIndicator={false}
                    pagingEnabled
                    data={imagesArray}
                    style={{
                        flex: 1,
                    }}
                    viewabilityConfig={viewabilityConfig.current}
                    onViewableItemsChanged={onViewableItemsChanged.current}
                    renderItem={({item, i}) => (
                        <View
                            style={{
                                flex: 1,
                            }}>
                            <Image
                                source={{uri: item.url}}
                                style={{
                                    width: width-20,
                                    height: height/4.5,
                                    borderRadius: 20
                                }}/>
                        </View>
                    )}/>
                <View
                    style={{
                        height: 20,
                        position: 'absolute',
                        borderRadius: 20,
                        justifyContent: 'space-between',
                        bottom: 5,
                        alignSelf: 'center',
                        flexDirection: 'row',
                        backgroundColor: '#FFFFFF17'
                    }}>
                    {images.map((item, index) => (
                        <View
                            style={{
                                paddingLeft: index == 0 ? 5 : 3,
                                paddingRight: index == images.length-1 ? 5 : 3,
                                alignSelf: 'center'
                            }}
                            key={index}>
                            <View
                                style={{
                                    height: 8, 
                                    width: 8, 
                                    borderRadius: 360,
                                    alignSelf: 'center',
                                    backgroundColor: index == currentIndex ? 'white' : '#FFFFFF38'
                                }}/>
                        </View>
                    ))}    
                </View>
            </View>
        </View>
    )
}

export default ImageViewer;