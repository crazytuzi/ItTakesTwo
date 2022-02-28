UCLASS(Abstract, HideCategories = "Rendering Cooking Debug Actor Tags LOD AssetUserData")
class ASeekingEyePointLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	UPointLightComponent PointLightComp;
	default PointLightComp.Mobility = EComponentMobility::Stationary;

	UPROPERTY()
	UCurveFloat IntensityCurve;

	UPROPERTY()
	float MaximumIntensity = 0.5f;

	void UpdateIntensity(float Dot)
	{
		float CurAlpha = IntensityCurve.GetFloatValue(Dot);
		float CurIntensity = FMath::Lerp(0.f, MaximumIntensity, CurAlpha);
		PointLightComp.SetIntensity(CurIntensity);

		Print("" + Dot);
	}
}