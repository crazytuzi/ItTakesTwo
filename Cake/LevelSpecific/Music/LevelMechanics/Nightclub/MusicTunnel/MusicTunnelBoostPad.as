import Cake.LevelSpecific.Music.LevelMechanics.Nightclub.MusicTunnel.MusicTunnelVehicle;
import Cake.LevelSpecific.Music.LevelMechanics.Nightclub.MusicTunnel.MusicTunnelComponent;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

UCLASS(Abstract, HideCategories = "Rendering Debug Collision Replication Actor Input LOD Cooking")
class AMusicTunnelBoostPad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BoostPadRootScene;

	UPROPERTY(DefaultComponent, Attach = BoostPadRootScene)
	UStaticMeshComponent BoostPadMesh;
	
	UPROPERTY(DefaultComponent, Attach = BoostPadRootScene)
	UBoxComponent Trigger;

	UPROPERTY()
	UAkAudioEvent BoostPadEvent;	

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMusicTunnelComponent TunnelComp;

	UPROPERTY()
	UFoghornVOBankDataAssetBase VOBank;

	UPROPERTY(Category = "Properties")
	float BoostValue = 500.f;

	UPROPERTY(Category = "Properties")
	float RotationOffset = 0.f;

	float OffsetFromCenter = 600.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (TunnelComp != nullptr && TunnelComp.TargetSplineActor != nullptr)
		{
			USplineComponent TargetSplineComp = USplineComponent::Get(TunnelComp.TargetSplineActor);
			FTransform ClosestTransformOnSpline = TargetSplineComp.FindTransformClosestToWorldLocation(GetActorLocation(), ESplineCoordinateSpace::World);

			SetActorTransform(ClosestTransformOnSpline);
			BoostPadRootScene.SetWorldLocation(GetActorLocation() + FVector::UpVector * -OffsetFromCenter);
			BoostPadRootScene.SetRelativeRotation(FRotator(0.f, 180.f, 0.f));
			SetActorRotation(FRotator(GetActorRotation().Pitch, GetActorRotation().Yaw, RotationOffset));
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AMusicTunnelVehicle Vehicle = Cast<AMusicTunnelVehicle>(OtherActor);
		if (Vehicle != nullptr)
		{
			Vehicle.ActivateBoost(BoostValue);
			
			
			if (Vehicle.OwningPlayer.IsCody())
				PlayFoghornVOBankEvent(VOBank, n"FoghornDBMusicNightClubAudiosurfSpeedBoostEffortCody");
			else
				PlayFoghornVOBankEvent(VOBank, n"FoghornDBMusicNightClubAudiosurfSpeedBoostEffortMay");


			if(BoostPadEvent != nullptr)
			{
				FOnAkPostEventCallback Callback;
				AkGameplay::PostEvent(BoostPadEvent, this, 0);
			}
		}
	}
}