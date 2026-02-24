import React from "react";
import {
    View,
    Text,
    TouchableOpacity,
    DeviceEventEmitter,
    ScrollView
} from 'react-native';
import { Icon } from "react-native-elements";
import styles from "../Styles";
import { Modalize } from "react-native-modalize";
import CompanyCategorySelectionList from "../Components/CompanyCategorySelectionList";
import categoryStore from "../services/categoryStore";
import arrayHelper from "../helpers/arrayHelper";
import ImageBox from "../Components/ImageBox";
import CustomTextInput from "../Components/CustomTextInput";

const AboutScreen = ({handleState}) => {
    const modalRef = React.useRef(null);

    const categories = categoryStore.getCategories();

    const [fisrtImageUri, setFirstImageUri] = React.useState('');
    const [secondImageUri, setSecondImageUri] = React.useState('');
    const [thirdImageUri, setThirdImageUri] = React.useState('');
    const [fourthImageUri, setFourthImageUri] = React.useState('');
    const [fivthImageUri, setFivthImageUri] = React.useState('');
    const [sixthImageUri, setSixthImageUri] = React.useState('');

    const [prepayment, setPrepayment] = React.useState(false);
    const [description, setDescription] = React.useState('');

    const [selectedCategories, setSelectedCategories] = React.useState(
        Object.keys(categories).map((i) => ({
            id: categories[i].id,
            title: categories[i].title,
            tracked: false,
            add: (increaseOrDecrease) => countChanged(increaseOrDecrease)
        }))
    );

    const countChanged = (increaseOrDecrease) => {
        setCategoryCount(prev => increaseOrDecrease ? prev+1 : prev-1);
    }

    const [categoryCount, setCategoryCount] = React.useState(arrayHelper.where(selectedCategories, (c) => c.tracked).length);

    const getCategoryString = () => {
        let sortedArray = arrayHelper.where(selectedCategories, (c) => c.tracked);
        let string = arrayHelper.project(sortedArray, (c) => c.title).join(',');

        return string == '' ? 'Виды деятельности' : string;
    };

    const projectCategoriesToIntArray = () => {
        let sortedArray = arrayHelper.where(selectedCategories, (c) => c.tracked);

        return arrayHelper.project(sortedArray, (c) => c.id);
    }

    const [categoryString, setCategoryString] = React.useState(getCategoryString);

    return (
        <View
            style={{
                flex: 1,
                backgroundColor: 'white',
                paddingTop: 10,
                paddingHorizontal: 20,
            }}>
            <Modalize
                ref={modalRef}
                adjustToContentHeight={true}
                childrenStyle={{height: '90%'}}>
                <View
                    style={{flex: 1}}>
                    <View
                        style={{
                            justifyContent: 'space-between',
                            flexDirection: 'row',
                            paddingHorizontal: 20,
                            paddingTop: 10
                        }}>
                        <Text></Text>
                        <Text
                            style={{
                                fontSize: 21,
                                fontWeight: '600',
                                color: 'black'
                            }}>
                            Виды деятельности
                        </Text>
                        <TouchableOpacity
                            style={{
                                borderRadius: 360,
                                backgroundColor: '#eff1f2',
                            }}
                            onPress={() => {
                                modalRef.current?.close();
                                setCategoryCount(arrayHelper.where(selectedCategories, (c) => c.tracked).length);
                            }}>
                            <Icon
                                name='close'
                                type='material'
                                size={27}
                                color='#818C99'/>
                        </TouchableOpacity>
                    </View>
                    <CompanyCategorySelectionList 
                        categories={selectedCategories}/>
                    <View
                        style={{
                            paddingHorizontal: 10,
                            paddingTop: 20
                        }}>
                        <TouchableOpacity
                            style={styles.button}
                            onPress={() => {
                                DeviceEventEmitter.emit('addCategories');
                                modalRef.current?.close();
                                setCategoryString(getCategoryString());       
                            }}>
                            <Text
                                style={styles.buttonText}>
                                {categoryCount == 0 ? 'Выбрать' : `Выбрать (${categoryCount})`}
                            </Text>
                        </TouchableOpacity>
                    </View>
                </View>
            </Modalize>
            <ScrollView
                style={{
                    flex: 1,
                    backgroundColor: 'white',
                }}
                showsVerticalScrollIndicator={false}>
                <Text
                    style={{
                        color: 'black',
                        fontWeight: '700',
                        fontSize: 17
                    }}>
                    О работе    
                </Text>
                <Text
                    style={{
                        paddingTop: 20,
                        paddingBottom: 5,
                        color: '#6D7885', 
                        fontWeight: '400', 
                        fontSize: 14,
                    }}>
                    Описание    
                </Text>
                <CustomTextInput
                        value={description}
                        changed={setDescription}
                        big
                        placeholder={'Введите описание'}
                        multiline/>
                <Text
                    style={{
                        color: '#6D7885', 
                        fontWeight: '400', 
                        fontSize: 14, 
                        paddingTop: 20,
                        paddingBottom: 5
                    }}>
                    Виды деятельности        
                </Text>
                <View>
                    <View style={[styles.textInput(false, false), {justifyContent: 'center'}]}>
                        <View
                            style={{
                                justifyContent: 'space-between',
                                flexDirection: 'row'
                            }}>
                            <Text
                                style={{
                                    color: categoryCount == 0 ? '#818C99' : 'black',
                                    fontSize: 16,
                                    fontWeight: '400',
                                    flex: 2
                                }}>
                                {categoryString}
                            </Text>
                            <TouchableOpacity 
                                style={{
                                    alignSelf: 'center'    
                                }}
                                onPress={() => modalRef.current?.open()}>
                                <Icon
                                    color='gray'
                                    type='material'
                                    name='expand-more'/>
                            </TouchableOpacity>
                        </View>
                    </View>
                </View>
                <Text 
                    style={{
                        color: '#6D7885', 
                        fontWeight: '400', 
                        fontSize: 14, 
                        paddingTop: 20,
                        paddingBottom: 5
                    }}>
                    Добавьте фотографии
                </Text>
                <View
                    style={{
                        justifyContent: 'space-between',
                        flexDirection: 'row'
                    }}>
                    <ImageBox
                        uri={fisrtImageUri}
                        onUriChanged={(uri) => setFirstImageUri(uri)}/>

                    <ImageBox
                        uri={secondImageUri}
                        onUriChanged={(uri) => setSecondImageUri(uri)}/>

                    <ImageBox
                        uri={thirdImageUri}
                        onUriChanged={(uri) => setThirdImageUri(uri)}/>          
                </View>
                <View
                    style={{
                        paddingTop: 5,
                        justifyContent: 'space-between',
                        flexDirection: 'row'
                    }}>
                    <ImageBox
                        uri={fourthImageUri}
                        onUriChanged={(uri) => setFourthImageUri(uri)}/>

                    <ImageBox
                        uri={fivthImageUri}
                        onUriChanged={(uri) => setFivthImageUri(uri)}/>

                    <ImageBox
                        uri={sixthImageUri}
                        onUriChanged={(uri) => setSixthImageUri(uri)}/>          
                </View>
                <View
                    style={{
                        flexDirection: 'column',
                        paddingTop: 20
                    }}>
                    <Text
                        style={{
                            color: '#6D7885', 
                            fontWeight: '400', 
                            fontSize: 14, 
                            paddingBottom: 5
                        }}>
                        Опции    
                    </Text>
                    <View
                        style={{
                            flexDirection: 'row'
                        }}>
                        <TouchableOpacity
                            style={{
                                alignSelf: 'center'
                            }}
                            disabled={prepayment}
                            onPress={() => {
                                setPrepayment(true);
                            }}>
                            <Icon 
                                type='material'
                                name={prepayment ? 'radio-button-checked' : 'radio-button-unchecked'}
                                color={!prepayment ? '#B8C1CC' : '#2688EB'}/>
                        </TouchableOpacity>
                        <Text
                            style={{
                                paddingLeft: 10,
                                color: 'black',
                                fontSize: 15,
                                fontWeight: '400',
                                alignSelf: 'center'
                            }}>
                            Работа с предоплатой    
                        </Text>
                    </View>
                    <View
                        style={{
                            flexDirection: 'row',
                            paddingTop: 20
                        }}>
                        <TouchableOpacity
                            style={{
                                alignSelf: 'center'
                            }}
                            disabled={!prepayment}
                            onPress={() => {
                                setPrepayment(false);
                            }}>
                            <Icon 
                                type='material'
                                name={!prepayment ? 'radio-button-checked' : 'radio-button-unchecked'}
                                color={prepayment ? '#B8C1CC' : '#2688EB'}/>
                        </TouchableOpacity>
                        <Text
                            style={{
                                paddingLeft: 10,
                                color: 'black',
                                fontSize: 15,
                                fontWeight: '400',
                                alignSelf: 'center'
                            }}>
                            Работа без предоплаты  
                        </Text>
                    </View>    
                </View>
                <View
                    style={{
                        paddingTop: 40,
                        paddingBottom: 20
                    }}>
                    <TouchableOpacity
                        style={[
                            styles.button, { 
                                backgroundColor: categoryCount == 0 || description == '' ? '#ABCDf3' : '#2D81E0',
                            }
                        ]}
                        disabled={categoryCount == 0 || description == ''}
                        onPress={(categoryCount != 0 && description != '') && (() => handleState({
                            photoUris: [
                                fisrtImageUri, 
                                secondImageUri, 
                                thirdImageUri,
                                fourthImageUri,
                                fivthImageUri,
                                sixthImageUri
                            ],
                            prepayment,
                            description,
                            categories: projectCategoriesToIntArray()
                        }))}>
                        <Text
                            style={styles.buttonText}>
                            Сохранить
                        </Text>
                    </TouchableOpacity>
                </View>
            </ScrollView>
        </View>
    )
}

export default AboutScreen;