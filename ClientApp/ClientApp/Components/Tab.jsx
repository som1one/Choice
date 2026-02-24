import React from 'react';
import {
  View,
  Text,
  findNodeHandle,
  TouchableOpacity
} from 'react-native';


const Tab = React.forwardRef(({ item, onItemPress }, ref) => {
  return (
    <TouchableOpacity onPress={onItemPress}>
      <View ref={ref}>
        <Text 
          style={{
            color: 'black', 
            fontSize: 16, 
            fontWeight: '600'
          }}
        >
            {item.title}
        </Text>
      </View>
    </TouchableOpacity>
  );
});

export default Tab;