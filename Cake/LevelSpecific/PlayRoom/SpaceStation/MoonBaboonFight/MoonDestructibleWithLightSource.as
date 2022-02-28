import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonDestructible;

class AMoonDestructibleWithLightSource : AMoonDestructible
{
	UPROPERTY(DefaultComponent, Attach = RootComp, ShowOnActor)
	USpotLightComponent SpotLight;
}