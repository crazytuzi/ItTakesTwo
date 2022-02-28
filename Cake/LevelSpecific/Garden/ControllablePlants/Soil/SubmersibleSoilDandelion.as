import Cake.LevelSpecific.Garden.ControllablePlants.Soil.SubmersibleSoil;
import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.DandelionLaunchComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Soil.DandelionLaunchVisualizer;

class ASubmersibleSoilDandelion : ASubmersibleSoil
{
	UPROPERTY(DefaultComponent, ShowOnActor)
	UDandelionLaunchComponent DandelionLaunchComp;
}
