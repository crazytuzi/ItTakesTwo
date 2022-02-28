import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;

UCLASS(Abstract)
class AClockTownSiloTop : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SiloTopRoot;

	UPROPERTY(DefaultComponent, Attach = SiloTopRoot)
	UStaticMeshComponent SiloTopMesh;

	UPROPERTY(DefaultComponent, Attach = SiloTopRoot)
	UTimeControlActorComponent TimeControlComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 10000.f;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SiloTopMesh.SetCullDistance(Editor::GetDefaultCullingDistance(SiloTopMesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeControlComp.TimeIsChangingEvent.AddUFunction(this, n"TimeIsChanging");
	}

	UFUNCTION(NotBlueprintCallable)
	void TimeIsChanging(float PointInTime)
	{
		float CurHeight = FMath::Lerp(150.f, -930.f, PointInTime);
		SiloTopRoot.SetRelativeLocation(FVector(0.f, 0.f, CurHeight));
	}
}