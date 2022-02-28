import Editor.Props.HazeLightActionUtility;

class UHazeSpotLightActionUtility : UHazeLightActionUtility
{
	UFUNCTION(BlueprintOverride)
    UClass GetSupportedClass() const
    {
		return ASpotLight::StaticClass();
    }

	UFUNCTION(CallInEditor, Category = "Static Light Actions")
    void SelectStaticSpotLights()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(ASpotLight::StaticClass()), EComponentMobility::Static);
	}

	UFUNCTION(CallInEditor, Category = "Stationary Light Actions")
    void SelectStationarySpotLights()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(ASpotLight::StaticClass()), EComponentMobility::Stationary);
	}

	UFUNCTION(CallInEditor, Category = "Stationary Light Actions")
    void SelectShadowCastingStationarySpotLights()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(ASpotLight::StaticClass()), EComponentMobility::Stationary, true);
	}

	UFUNCTION(CallInEditor, Category = "Movable Light Actions")
    void SelectMovableSpotLights()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(ASpotLight::StaticClass()), EComponentMobility::Movable);
	}
}