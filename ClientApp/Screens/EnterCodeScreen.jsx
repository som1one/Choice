import React from "react";
import {
    View,
    Text,
    Dimensions,
    TouchableOpacity,
} from 'react-native';
import { AuthContext } from "../App";
import AsyncStorage from "@react-native-async-storage/async-storage";

const EnterCodeScreen = () => {
    const [code, setCode] = React.useState('');
    const nums = [1,2,3,4,5,6,7,8,9,0];
    const wh = Dimensions.get('screen');
    const { enterCode } = React.useContext(AuthContext);
    const [isFirstTime, setIsFirstTime] = React.useState(false);
    const [error, setError] = React.useState(false);
    const btnWidth = wh.width/4.5;

    React.useEffect(() => {
        async function getEditMode(){
            const value = await AsyncStorage.getItem('code');

            setIsFirstTime(value == null);
        }
        getEditMode();
    }, []);

    const process = async (prevCode) => {
        console.log(prevCode);
        if (prevCode.length == 4) {
            if (isFirstTime) {
                await AsyncStorage.setItem('code', prevCode);
                enterCode();
            }
            else {
                let storedCode = await AsyncStorage.getItem('code');

                if (prevCode != storedCode) {
                    setError(true);
                    setCode('');
                }
                else {
                    enterCode();
                }
            }
        }
    }

    const set = async (text) => {
        setError(false);
        setCode(prev => `${prev}${text}`);
        await process(`${code}${text}`);
    }

    return (
        <View
            style={{
                flex: 1,
                backgroundColor: 'white',
            }}>
            <Text
                style={{
                    paddingTop: 20,
                    fontSize: 21,
                    color: 'black',
                    fontWeight: '600',
                    alignSelf: 'center'
                }}>
                Введите код
            </Text>
            <View
                style={{
                    paddingTop: 40,
                    flexDirection: 'row',
                    justifyContent:  'center'
                }}>
                {[1,2,3,4].map(n => (
                    <View
                        key={n}
                        style={{
                            paddingLeft: n == 1 ? 0 : 10
                        }}>
                        <View
                            style={{
                                height: 10,
                                width: 10,
                                borderRadius: 360,
                                backgroundColor: error ? 'red' : code.length >= n ? '#2D81E0' : '#dee2e6'
                            }}/>
                    </View>
                ))}
            </View>
            <View
                style={{
                    flexDirection: 'row',
                    flexWrap: 'wrap',
                    justifyContent: 'center',
                    paddingTop: 40,
                    paddingHorizontal: 40
                }}>
                {nums.map(n => (
                    <View
                        style={{
                            paddingRight: n == 1 || n == 4 || n == 7 ? 10 : 0,
                            paddingLeft: n == 3 || n == 6 || n == 9 ? 10 : 0,
                            paddingTop: n <= 3 && n != 0 ? 0 : 10
                        }}>
                        <TouchableOpacity
                            style={{
                                backgroundColor: '#2D81E0',
                                width: btnWidth,
                                height: btnWidth,
                                borderRadius: 360,
                                justifyContent: 'center'
                            }}
                            onPress={async () => await set(n)}>
                            <Text
                                style={{
                                    fontSize: 31,
                                    fontWeight: '600',
                                    color: 'white',
                                    alignSelf: 'center'
                                }}>
                                {n}
                            </Text>
                        </TouchableOpacity>
                    </View>
                ))}
            </View>
        </View>
    );
}

export default EnterCodeScreen;