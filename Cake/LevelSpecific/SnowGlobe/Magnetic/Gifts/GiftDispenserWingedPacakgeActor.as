import Cake.LevelSpecific.SnowGlobe.Magnetic.Gifts.GiftDispenserActor;
import Peanuts.Spline.SplineActor;
import Cake.LevelSpecific.SnowGlobe.WingedPackage.WingedPackage;

UCLASS(Abstract)
class AGiftDispenserWingedPackage : AGiftDispenserActor
{
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpawnLocation2;

	UPROPERTY()
	AHazeActor Gift2;

	UPROPERTY()
	ASplineActor FlyInCircleSplineActor1;
	
	UPROPERTY()
	ASplineActor FlyInCircleSplineActor2;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Gift = Cast<AHazeActor>(SpawnActor(GiftClass, SpawnLocation.WorldLocation, SpawnLocation.WorldRotation, bDeferredSpawn = true));
		Gift2 = Cast<AHazeActor>(SpawnActor(GiftClass, SpawnLocation2.WorldLocation, SpawnLocation.WorldRotation, bDeferredSpawn = true));

		Gift.MakeNetworked(this, Game::GetCody());
		FinishSpawningActor(Gift);

		Gift2.MakeNetworked(this, Game::GetMay());
		FinishSpawningActor(Gift2);

		Gift.AddCapability(n"WingedPackageFlyingCapability");
		Gift2.AddCapability(n"WingedPackageFlyingCapability");

		Gift.DisableActor(this);
		Gift2.DisableActor(this);

		Cast<AWingedPackage>(Gift).FlyInCircleSplineActor = FlyInCircleSplineActor1;
		Cast<AWingedPackage>(Gift2).FlyInCircleSplineActor = FlyInCircleSplineActor2;
	}

	UFUNCTION()
	void SpawnGift() override
	{
		if (!bCompletedGift)
		{
			Gift.EnableActor(this);
			Gift2.EnableActor(this);
			Gift.SetActorLocationAndRotation(SpawnLocation.GetWorldLocation(), SpawnLocation.GetWorldRotation());
			Gift2.SetActorLocationAndRotation(SpawnLocation2.GetWorldLocation(), SpawnLocation2.GetWorldRotation());
		}
	}
}