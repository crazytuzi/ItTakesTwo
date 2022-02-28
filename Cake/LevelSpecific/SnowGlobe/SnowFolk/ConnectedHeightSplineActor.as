import Cake.LevelSpecific.SnowGlobe.Snowfolk.ConnectedHeightSplineComponent;

UCLASS(HideCategories = "Physics Collision Lighting Rendering VirtualTexture Debug Activation Tags HLOD Mobile AssetUserData")
class AConnectedHeightSplineActor : AHazeSplineActor
{
    UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
    UConnectedHeightSplineComponent ConnectedHeightSplineComponent;

    UPROPERTY(DefaultComponent, NotEditable)
    UBillboardComponent BillboardComponent;
	default BillboardComponent.SetRelativeScale3D(4.f);
    default BillboardComponent.SetRelativeLocation(FVector(0, 0, 150));
    default BillboardComponent.Sprite = Asset("/Engine/EditorResources/Spline/T_Loft_Spline.T_Loft_Spline");

	UFUNCTION(CallInEditor, Category = "ConnectedHeightSplineActor")
	void BakeAllConnectedSplinesHeightData()
	{
		ConnectedHeightSplineComponent.BakeAllConnectedSplinesHeightData();
	}
}