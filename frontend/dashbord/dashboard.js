const attendaceData=[
    {day:"Sat",percentage:91},
    {day:"sun",percentage:74},
    {day:"Mon",percentage:88},
    {day:"Tue",percentage:96},
    {day:"Wed",percentage:93},
    {day:"Thu",percentage:75}
];
const chartLine = document.querySelector(".chart-line");
const chartSvg = document.createElementNS("http://www.w3.org/2000/svg","svg");
    chartSvg.setAttribute("viewBox","0 0 100 100");
    chartSvg.setAttribute("preserveAspectRatio","none");

     chartLine.appendChild(chartSvg);

    const points = attendaceData.map((item, index) => {
        const x = (index / (attendaceData.length-1))*100;
        const y = 100 -((item.percentage - 60)/40) * 100;
        return `${x},${y}`;
    } ).join(" ");

      const polyline = document.createElementNS("http://www.w3.org/2000/svg",
        "polyline");

    polyline.setAttribute("points" , points);
    polyline.setAttribute("fill" , "none");
    polyline.setAttribute("stroke" , "#2f6cb1");
    polyline.setAttribute("stroke-width" , "2");
    

    polyline.setAttribute("vector-effect","non-scaling-stroke");

    chartSvg.appendChild(polyline);

    const tooltip = document.createElement("div");
    tooltip.classList.add("chart-tooltip");
    document.body.appendChild(tooltip);


    attendaceData.forEach((item,index) => {

    const point = document.createElement("div");
    point.classList.add("chart-point");

    point.dataset.day = item.day;
    point.dataset.percentage = item.percentage;

    point.addEventListener("mouseenter",()=>{
        point.title = `${item.day}: ${item.percentage}%`;
         tooltip.style.opacity = "1";
    });

   

    const position = (index/(attendaceData.length - 1)) * 100;
    
    const height = ((item.percentage-60)/40)*100;

    point.style.left=`${position}%`;
    point.style.bottom = `${height}%`;
    chartLine.appendChild(point);

});

const addStudentBtn = document.querySelector(".quick-action-card");
addStudentBtn.addEventListener("click",()=>{
    alert("Add student clicked !");
});