import React from 'react';
import {
  View,
  Dimensions,
  findNodeHandle,
  TouchableOpacity,
  Text
} from 'react-native';
import Tab from './Tab.jsx';
import Indicator from './Indicator.jsx';

const {width, height} = Dimensions.get('screen');

const Tabs = ({ data, scrollX, onItemPress, admin }) => {
    const [measures, setMeasures] = React.useState([]);
    const containerRef = React.useRef();
    React.useEffect(() => {
        let m = [];
        data.forEach(item => {
            item.ref.current.measureLayout(
                containerRef.current,
                (x, y, width, height) => {
                    m.push({
                        x, 
                        y, 
                        width, 
                        height
                    });

                    if (m.length === data.length) {
                        setMeasures(m);
                    }
                }
            );
        })
    }, [containerRef.current]);
    
    return (
        <View style={{width}}>
            <View style={{justifyContent: admin ? 'space-between' : 'space-evenly', flex: 1, flexDirection: 'row', paddingHorizontal: admin ? 15 : 0}} ref={containerRef}>
                {data.map((item, index) => {return (
                    <Tab key={item.key} item={item} ref={item.ref} onItemPress={() => onItemPress(index)}/>
                )})}
            </View>
            { measures.length > 0 && <Indicator measures={measures} scrollX={scrollX} data={data} admin={admin}/>}
        </View>
    );
}

export default Tabs;