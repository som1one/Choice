import React from 'react';
import {
  View,
  Animated,
  findNodeHandle,
  Dimensions
} from 'react-native';

const {width, height} = Dimensions.get('screen');

const Indicator = ({measures, scrollX, data, admin}) => {
    const inputRange = data.map((_, i) => i * width);
    const indicatorWidth = !admin ? width/2.5 : scrollX.interpolate({
        inputRange,
        outputRange: measures.map(measure => measure.width+measure.width*0.2)
    })
    const translateX = scrollX.interpolate({
        inputRange: inputRange,
        outputRange: measures.map(measure => !admin ? measure.x-width/5+measure.width/2 : measure.x-((measure.width+measure.width*0.2)/2)+measure.width/2)
    });
    return (
        <Animated.View style={{
            position: 'absolute',
            height: 2.5,
            width: indicatorWidth,
            backgroundColor: '#3F8AE0',
            borderRadius: 10,
            bottom: -10,
            transform: [{
                translateX
            }]
        }}/>
    );
}

export default Indicator;