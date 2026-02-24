
const project = (array, predicate) => {
    let projectedArray = [];

    array.forEach(item => {
        projectedArray.push(predicate(item));
    })
    
    return projectedArray;
}

const where = (array, predicate) => {
    let sortedArray = [];

    array.forEach(item => {
        if (predicate(item)) {
            sortedArray.push(item);
        }
    });

    return sortedArray;
}

const lastOrDefault = (array, predicate) => {
    for (let i = array.length-1; i >= 0; i--) {
        if (predicate(array[i])) {
            return i;
        }
    }

    return -1;
}

export default {
    project,
    where,
    lastOrDefault
}