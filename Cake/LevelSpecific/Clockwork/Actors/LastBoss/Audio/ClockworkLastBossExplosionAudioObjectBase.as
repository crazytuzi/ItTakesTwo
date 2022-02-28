import void RegisterAudioFXObject(UClockworkLastBossExplosionAudioObjectBase) from "Cake.LevelSpecific.Clockwork.Actors.LastBoss.Audio.ClockworkLastBossExplosionAudioStatics";
import void UnregisterAudioFXObject(UClockworkLastBossExplosionAudioObjectBase) from "Cake.LevelSpecific.Clockwork.Actors.LastBoss.Audio.ClockworkLastBossExplosionAudioStatics";

import Peanuts.Audio.AudioStatics;

struct FClockworkExplosionTimelineSound
{
	UPROPERTY()
	UAkAudioEvent ForwardsEvent = nullptr;

	UPROPERTY()
	float ForwardTimelinePos = 0.f;

	UPROPERTY()
	UAkAudioEvent ReverseEvent = nullptr;

	UPROPERTY()
	float ReverseTimelinePos = 0.f;

	UHazeAkComponent HazeAkComp = nullptr;
}

class UClockworkLastBossExplosionAudioObjectBase : USceneComponent
{
	UPROPERTY()
	UAkAudioEvent BaseEvent = nullptr;

	UPROPERTY()
	bool bPlayOnStart = true;

	UPROPERTY(meta = (EditCondition = "!bPlayOnStart"))
	float TimelinePosStart = 0.f;

	UPROPERTY(meta = (EditCondition = "!bPlayOnStart"))
	float TimelinePosStop = 0.f;

	UPROPERTY()
	bool bUseMultiPositioning = false;

	UPROPERTY(meta = (EditCondition = "bUseMultiPositioning"))
	HazeAudio::EHazeMultiplePositionsTrackingType MultiplePositionsTrackingType = HazeAudio::EHazeMultiplePositionsTrackingType::BothPlayers;

	UPROPERTY()
	bool bTrackVelocity = false;

	UPROPERTY(meta = (EditCondition = "bTrackVelocity"))
	float MaxSpeed = 0.f;

	UPROPERTY()
	bool bDebug = false;

	UHazeAkComponent HazeAkComp;	
	UStaticMeshComponent StaticMesh;
	USkeletalMeshComponent SkelMesh;	
	protected FHazeAudioEventInstance EventInstance;

	default PrimaryComponentTick.SetbStartWithTickEnabled(false);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RegisterAudioFXObject(this);		
	}

	UFUNCTION()
	void BeginExplosionStarted()
	{
		if(bUseMultiPositioning)
		{
			StaticMesh = UStaticMeshComponent::Get(Owner);
			SkelMesh = USkeletalMeshComponent::Get(Owner);			
			HazeAkComp.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		}		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		if(bUseMultiPositioning)
		{
			TArray<FTransform> EmitterPositions;	

			FTransform OutMayTrans;
			FTransform OutCodyTrans;

			for(auto Player : Game::GetPlayers())
			{	
				FVector OutPoint;
				GetClosestPoint(Player.GetActorCenterLocation(), OutPoint);

				if(Player.IsMay() && MultiplePositionsTrackingType != HazeAudio::EHazeMultiplePositionsTrackingType::Cody)
				{
					OutMayTrans = FTransform(OutPoint);
					EmitterPositions.Add(OutMayTrans);
				}
				else if(MultiplePositionsTrackingType != HazeAudio::EHazeMultiplePositionsTrackingType::May)
				{
					OutCodyTrans = FTransform(OutPoint);
					EmitterPositions.Add(OutCodyTrans);
				}
			}

			if(EmitterPositions.Num() > 0)
				HazeAkComp.HazeSetMultiplePositions(EmitterPositions);

			if(bDebug)
			{
	#if EDITOR
				if(MultiplePositionsTrackingType != HazeAudio::EHazeMultiplePositionsTrackingType::Cody)
					System::DrawDebugBox(OutMayTrans.Location, 50.f, FLinearColor::Blue);
				if(MultiplePositionsTrackingType != HazeAudio::EHazeMultiplePositionsTrackingType::May)
					System::DrawDebugBox(OutCodyTrans.Location, 50.f, FLinearColor::Green);
	#endif
			}
		}	
	}

	UFUNCTION()
	void OnTimeChanged(const float& NewCurrentTime)
	{
		if(bPlayOnStart)
			return;

		if(NewCurrentTime >= TimelinePosStart && NewCurrentTime <= TimelinePosStop)
		{
			if(!HazeAkComp.EventInstanceIsPlaying(EventInstance))
				EventInstance = HazeAkComp.HazePostEvent(BaseEvent);		
		}
		else if(HazeAkComp.EventInstanceIsPlaying(EventInstance))
			HazeAkComp.HazeStopEvent(EventInstance.PlayingID);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UnregisterAudioFXObject(this);

		if(HazeAkComp != nullptr)
		{
			if(HazeAkComp.EventInstanceIsPlaying(EventInstance))
				HazeAkComp.HazeStopEvent(EventInstance.PlayingID);
		}
	}

	void GetClosestPoint(const FVector InVector, FVector& OutVector)
	{
		if(SkelMesh != nullptr)
		{			
			FVector OutNormal;
			float OutDistance;
			FName OutBoneName;

			SkelMesh.GetClosestPointOnPhysicsAsset(InVector, OutVector, OutNormal, OutBoneName, OutDistance);
		}

		else if(StaticMesh != nullptr)
		{
			StaticMesh.GetClosestPointOnCollision(InVector, OutVector);
		}
	}
}