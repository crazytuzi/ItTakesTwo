import Cake.LevelSpecific.SnowGlobe.Snowfolk.ConnectedHeightSplineFollowerComponent;
import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingBeetle;
import Cake.Weapons.Sap.SapAutoAimTargetComponent;
import Cake.Weapons.Match.MatchHitResponseComponent;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Tree.Wasps.Audio.WaspVOManager;

class ATreeBeetleRidingEnemy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase WaspSkeletalMesh;

	UPROPERTY(DefaultComponent, Attach = WaspSkeletalMesh, AttachSocket = "Hips")
	USceneComponent LarvaAttachPoint;

	UPROPERTY(DefaultComponent, Attach = LarvaAttachPoint)
	USceneComponent LarvaRoot;

	UPROPERTY(DefaultComponent)
	UConnectedHeightSplineFollowerComponent SplineFollowerComponent;

	UPROPERTY(DefaultComponent)
	USapAutoAimTargetComponent AutoAimTargetComponent;
	default AutoAimTargetComponent.TargetRadius = 0.f;
	default AutoAimTargetComponent.AutoAimMaxAngle = 15.f;
	default AutoAimTargetComponent.MaximumDistance = 10000.f;

	UPROPERTY(DefaultComponent)
	UMatchHitResponseComponent MatchHitResponseComponent;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent, Attach = LarvaRoot)
	UHazeAkComponent LarvaHazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartFlyingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopFlyingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DeathExploEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DropLarvaEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopLarvaEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LarvaExploEvent;

	UAkAudioEvent DropLarvaVOEvent;
	UAkAudioEvent DeathVOEvent; 

	private FHazeAudioEventInstance DropLarvaVOEventInstance;

	UPROPERTY()
	float Speed = 500.f;

	UPROPERTY()
	float Distance = 0.f;

	UPROPERTY()
	float Offset = 0.f;

	UPROPERTY()
	float HeightOffset = 1000.f;

	float Height = HeightOffset;

	UPROPERTY()
	float MinAggroDistance = 2000.f;

	UPROPERTY()
	float MaxAggroDistance = 6000.f;

	UPROPERTY()
	float MinAttackDistance = 1000.f;

	UPROPERTY()
	float MaxAttackDistance = 2000.f;

	UPROPERTY()
	float DropDistance = 6000.f;

	UPROPERTY()
	float LarvaDamage = 2.f;

	UPROPERTY()
	float DropDuration = 0.3f;
	float DropTimer = DropDuration;
	bool bLarvaHit;

	bool bIsAttacking;
	bool bIsLarvaDropped;
	bool bPlayedAttackVO = false;

	UPROPERTY()
	ATreeBeetleRidingBeetle TargetBeetle;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineFollowerComponent.DistanceOnSpline = Distance;
		SplineFollowerComponent.Offset = Offset;
		MatchHitResponseComponent.OnStickyHit.AddUFunction(this, n"OnMatchHit");

		HazeAkComp.SetStopWhenOwnerDestroyed(false);
		HazeAkComp.HazePostEvent(StartFlyingEvent);

		UWaspVOManager VOManager = UWaspVOManager::Get(Level.LevelScriptActor);

		if(VOManager != nullptr)
		{
			FBeetleRidingHeavyWaspVOEventData EventData = VOManager.GetNextAvaliableHeavyWaspEventData();
			DropLarvaVOEvent = EventData.OnAttackEvent;
			DeathVOEvent = EventData.OnKilledEvent;
		}

		Height = HeightOffset;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (SplineFollowerComponent.Spline == TargetBeetle.SplineFollowerComponent.Spline)
		{
			float DistanceToBeetle = SplineFollowerComponent.DistanceOnSpline - TargetBeetle.SplineFollowerComponent.DistanceOnSpline;

			if (DistanceToBeetle <= MaxAggroDistance && DistanceToBeetle >= MinAggroDistance)
			{
				bIsAttacking = true;
			}

			if (DistanceToBeetle <= MaxAttackDistance && DistanceToBeetle >= MinAttackDistance)
			{
				DropLarva();			
			}

			if (DistanceToBeetle < 0.f)
				bIsAttacking = false;

			if (bIsAttacking)
			{
				float Alpha = 1.f - FMath::Clamp(DistanceToBeetle, 0.f, DropDistance) / DropDistance;
				SplineFollowerComponent.Offset = FMath::Lerp(SplineFollowerComponent.Offset, TargetBeetle.SplineFollowerComponent.Offset, Alpha * 10.f * DeltaTime);

//				SplineFollowerComponent.Offset = FMath::Lerp(SplineFollowerComponent.Offset, TargetBeetle.SplineFollowerComponent.Offset, 1.f * DeltaTime);
				Height = FMath::Lerp(Height, 500.f, 1.f * DeltaTime);
//				Print("Attack!" + Alpha, 0.f, FLinearColor::Red);

				HazeAkComp.SetRTPCValue("Rtpc_Characters_Enemies_Wasps_IsAttacking", 1.f, 500);
				if(!bPlayedAttackVO)
				{
					DropLarvaVOEventInstance = HazeAkComp.HazePostEvent(DropLarvaVOEvent);
					bPlayedAttackVO = true;
				}
			}
			else
			{
				SplineFollowerComponent.Offset = FMath::Lerp(SplineFollowerComponent.Offset, Offset, 1.f * DeltaTime);
				Height = FMath::Lerp(Height, HeightOffset, 1.f * DeltaTime);

				HazeAkComp.SetRTPCValue("Rtpc_Characters_Enemies_Wasps_IsAttacking", 0.f, 500);
			}
		}
		else
		{
			SplineFollowerComponent.Offset = FMath::Lerp(SplineFollowerComponent.Offset, Offset, 1.f * DeltaTime);
			Height = FMath::Lerp(Height, HeightOffset, 1.f * DeltaTime);
		}

		SplineFollowerComponent.AddDistance(Speed * DeltaTime);

		FTransform TransformOnSpline = SplineFollowerComponent.GetSplineTransform(true);

	///	FVector Location = TransformOnSpline.Location + FVector::UpVector * Height;
		FVector Location = TransformOnSpline.Location + TransformOnSpline.Rotation.UpVector * Height;
		FRotator Rotation = FRotator::MakeFromX(TransformOnSpline.Rotation.ForwardVector * -1.f);

		SetActorLocationAndRotation(Location, Rotation);

		if (bIsLarvaDropped && !bLarvaHit)
		{
			DropTimer -= DeltaTime;

			if (DropTimer <= 0)
			{
				LarvaRoot.SetVisibility(false, true);
				bLarvaHit = true;
				TargetBeetle.TakeDamage(LarvaDamage, ETreeBeetleDamageType::LarvaBomb);
				LarvaHazeAkComp.HazePostEvent(LarvaExploEvent);
				LarvaHazeAkComp.HazePostEvent(StopLarvaEvent);
			//	Reset();
			}

			FVector LarvaLocation = LarvaRoot.WorldLocation;

			LarvaLocation.Z = FMath::Lerp(LarvaLocation.Z, TargetBeetle.ActorLocation.Z, 2.f * DeltaTime);
			LarvaRoot.SetWorldLocation(LarvaLocation);

			float DistanceToTarget = (LarvaLocation - TargetBeetle.ActorLocation).Size();

		//	if (DistanceToTarget < 400.f)
		//		TargetBeetle.TakeDamage();
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnMatchHit(AActor Match, UPrimitiveComponent ComponentBeingIgnited, FHitResult HitResult)
	{
		HazeAkComp.HazePostEvent(StopFlyingEvent);
		HazeAkComp.HazePostEvent(DeathExploEvent);

		if(HazeAkComp.EventInstanceIsPlaying(DropLarvaVOEventInstance))
			HazeAkComp.HazeStopEvent(DropLarvaVOEventInstance.PlayingID);

		HazeAkComp.HazePostEvent(DeathVOEvent);			
		DestroyActor();
	}

	UFUNCTION()
	void DropLarva()
	{
		bIsLarvaDropped = true;
		LarvaHazeAkComp.HazePostEvent(DropLarvaEvent);
	}

	UFUNCTION()
	void DisableWasp()
	{

	}

	UFUNCTION()
	void Reset()
	{
		DropTimer = DropDuration;
		bIsLarvaDropped = false;
		bLarvaHit = false;
		bIsAttacking = false;
		LarvaRoot.SetVisibility(true, true);
		LarvaRoot.SetRelativeLocation(FVector::ZeroVector);
	}
}