import userStore from "./userStore";

const apiKey = '893c71be7dfe47b897e4f622951e11af';

const getCoords = async () => {
    let user = userStore.get();
    let text = `${user.street},${user.city}`;

    return await fetch(`https://api.geoapify.com/v1/geocode/search?text=${text}&apiKey=${apiKey}`)
        .then(async response => {
            if (response.status == 200) {
                let json = await response.json();

                let lat = Number(`${json.features[0].properties.lat}`);
                let lon = Number(`${json.features[0].properties.lon}`);

                return [lat, lon];
            }
            else {
                return [];
            }
        });
}

export default {
    getCoords
}