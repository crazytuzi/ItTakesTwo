import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;

UCLASS(Abstract)
class ATimeControlWallWithHoles : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WallRoot;

	UPROPERTY(DefaultComponent, Attach = WallRoot)
	USceneComponent LeftRoot;

	UPROPERTY(DefaultComponent, Attach = LeftRoot)
	UStaticMeshComponent LeftWallMesh;

	UPROPERTY(DefaultComponent, Attach = LeftRoot)
	UStaticMeshComponent LeftWhacker;

	UPROPERTY(DefaultComponent, Attach = WallRoot)
	USceneComponent RightRoot;

	UPROPERTY(DefaultComponent, Attach = RightRoot)
	UStaticMeshComponent RightWallMesh;

	UPROPERTY(DefaultComponent, Attach = RightRoot)
	UStaticMeshComponent RightWhacker;

	UPROPERTY(DefaultComponent, Attach = WallRoot)
	UTimeControlActorComponent TimeControlComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeControlComp.TimeIsChangingEvent.AddUFunction(this, n"TimeIsChanging");
	}

	UFUNCTION(NotBlueprintCallable)
	void TimeIsChanging(float PointInTime)
	{
		// float CurHeight = FMath::Lerp(0.f, 400.f, PointInTime);
		// WallRoot.SetRelativeLocation(FVector::UpVector * CurHeight);

		float LeftLoc = FMath::Lerp(900.f, 600.f, PointInTime);
		LeftRoot.SetRelativeLocation(FVector(0.f, LeftLoc, 0.f));

		float RightLoc = FMath::Lerp(-600.f, -900.f, PointInTime);
		RightRoot.SetRelativeLocation(FVector(0.f, RightLoc, 150.f));
	}

	UFUNCTION()
	void ActivateLeftWhacker()
	{
		BP_ActivateWhacker(true);
	}

	UFUNCTION()
	void ActivateRightWhacker()
	{
		BP_ActivateWhacker(false);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateWhacker(bool bLeft) {}
}