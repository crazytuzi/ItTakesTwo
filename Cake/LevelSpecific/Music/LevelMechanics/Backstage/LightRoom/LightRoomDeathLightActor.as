class ALightRoomDeathLightActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPointLightComponent PointLight;
	default PointLight.SetIntensity(0.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}
}