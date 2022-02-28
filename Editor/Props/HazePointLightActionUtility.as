import Editor.Props.HazeLightActionUtility;

class UHazePointLightActionUtility : UHazeLightActionUtility
{
	UFUNCTION(BlueprintOverride)
    UClass GetSupportedClass() const
    {
		return APointLight::StaticClass();
    }

	UFUNCTION(CallInEditor, Category = "Static Light Actions")
    void SelectStaticPointLights()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(APointLight::StaticClass()), EComponentMobility::Static);
	}

	UFUNCTION(CallInEditor, Category = "Stationary Light Actions")
    void SelectStationaryPointLights()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(APointLight::StaticClass()), EComponentMobility::Stationary);
	}

	UFUNCTION(CallInEditor, Category = "Stationary Light Actions")
    void SelectShadowCastingStationaryPointLights()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(APointLight::StaticClass()), EComponentMobility::Stationary, true);
	}

	UFUNCTION(CallInEditor, Category = "Movable Light Actions")
    void SelectMovablePointLights()
	{
		GetAllLightsByMobility(TSubclassOf<AActor>(APointLight::StaticClass()), EComponentMobility::Movable);
	}
}