import Vino.PlayerHealth.TimedPlayerDeathEffect;
import Vino.Movement.Components.MovementComponent;

enum ERagdollBodyPart
{
	Head,
	Body,
	RighArm,
	LeftArm,
	RightLeg,
	LeftLeg
};

enum ERagdollBodyPartGroup
{
	Head,
	Body,
	Arms,
	Legs,
}

struct FRagdollAudioEvent
{
	UPROPERTY(Category = "Audio")
	ERagdollBodyPartGroup BodyGroup;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent ImpactEvent;

	UPROPERTY(Category = "Audio")
	float Cooldown = 1;

	UPROPERTY(Category = "Audio")
	float Threshold;

	UPROPERTY(Category = "Audio")
	float RtpcMinValue;

	UPROPERTY(Category = "Audio")
	float RtpcMaxValue;
};

struct FRagdollAudioEvents
{
	UPROPERTY(Category = "Audio")
	FRagdollAudioEvent HeadImpactEvent;

	UPROPERTY(Category = "Audio")
	FRagdollAudioEvent BodyImpactEvent;

	UPROPERTY(Category = "Audio")
	FRagdollAudioEvent HandArmImpactEvent;

	UPROPERTY(Category = "Audio")
	FRagdollAudioEvent FootLegImpactEvent;

	// How much increase in intensity triggers a re-trigger of the event. (in % / 100, i.e LastIntensity * Percentage)
	UPROPERTY(Category = "Audio")
	float IntensityIncreaseToRetrigger = 1.25f;
}

struct FTrackedTransform 
{
	FVector LastPosition;
	FVector LastVelocity;
	FHitResult LastHit;

	float Timer;
	float LastIntensity;
};

// TODO - clean up, ensure it works in all levels, and trace ignores trigger volumes.
class URagdollPlayerDeathEffect : UTimedPlayerDeathEffect
{
	UPROPERTY(Category = "AudioRagdoll")
	FRagdollAudioEvents MayAudioEvents;

	UPROPERTY(Category = "AudioRagdoll")
	FRagdollAudioEvents CodyAudioEvents;

	UPrimitiveComponent PrimitiveComp;

	TArray<EObjectTypeQuery> ObjectTypes;
	TArray<AActor> ActorsToIgnore;
	TArray<int> ActiveImpacts;
	TArray<FTrackedTransform> TrackedTransforms;
	TArray<FName> SocketsToTrack;
	int CurrentIndex;

	const float TraceDistanceThresholdSquared = 20 * 20;
	const FString HeadImpactRtpc = "Rtpc_Player_Ragdoll_Head_Impact_Intesity";
	const FString BodyImpactRtpc = "Rtpc_Player_Ragdoll_Body_Impact_Intesity";
	const FString HandArmImpactRtpc = "Rtpc_Player_Ragdoll_Arm_Impact_Intesity";
	const FString FootLegImpactRtpc = "Rtpc_Player_Ragdoll_Leg_Impact_Intesity";

	UFUNCTION()
	void SetRagdollsPrimitiveComponent(USkeletalMeshComponent MeshComponent)
	{
		PrimitiveComp = UPrimitiveComponent::Get(MeshComponent.Owner);
		Init();
	}

	void Init()
	{
		ActorsToIgnore.Reset();
		ActorsToIgnore.Add(PrimitiveComp.Owner);

		ObjectTypes.Reset();
		ObjectTypes.Add(EObjectTypeQuery::WorldStatic);

		if (SocketsToTrack.Num() > 0)
			return;

		SocketsToTrack.Add(n"Head");
		SocketsToTrack.Add(n"Spine1");
		SocketsToTrack.Add(n"RightForeArm");
		SocketsToTrack.Add(n"LeftForeArm");
		SocketsToTrack.Add(n"RightLeg");
		SocketsToTrack.Add(n"LeftLeg");
		for(int i=0;i < SocketsToTrack.Num(); ++i)
		{
			auto Transform = PrimitiveComp.GetSocketTransform(SocketsToTrack[i]);
			auto TrackedTransform = FTrackedTransform();
			TrackedTransform.LastPosition = Transform.Translation;

 			TrackedTransforms.Add(TrackedTransform);
		}
	}

	UFUNCTION()
	void FinishEffect() override
	{
		SocketsToTrack.Reset();
		ActiveImpacts.Reset();
		Super::FinishEffect();
	}

	void Tick(float DeltaTime) override
	{
		Super::Tick(DeltaTime);

		if (ActiveImpacts.Num() > 0) 
		{
			for(int Index = ActiveImpacts.Num()-1; Index >= 0; --Index)
			{
				FTrackedTransform& TrackedTransform = TrackedTransforms[Index];
				TrackedTransform.Timer -= DeltaTime;
				if (TrackedTransform.Timer <= 0)
				{
					TrackedTransform.LastIntensity = 0;
					ActiveImpacts.RemoveAtSwap(Index);
				}
			}
		}

		TrackVelocities(DeltaTime);
	}

	void TrackVelocities(float DeltaTime)
	{
		if (SocketsToTrack.Num() == 0)
			return;

		FTransform Transform = PrimitiveComp.GetSocketTransform(SocketsToTrack[CurrentIndex]);
		FTrackedTransform& TrackedTransform = TrackedTransforms[CurrentIndex];

		if (TrackedTransform.LastPosition.DistSquared(Transform.Translation) > TraceDistanceThresholdSquared)
		{
			// Exaggerate the movements
			FVector Direction = 
				Transform.Translation + 
				(Transform.Translation - TrackedTransform.LastPosition);

			FHitResult NewHit;
			if (System::LineTraceSingle(
				TrackedTransform.LastPosition,
				Direction,
				ETraceTypeQuery::Camera, false, ActorsToIgnore,
				EDrawDebugTrace::None,
				NewHit,
				false))
				{
					TrackedTransform.LastHit = NewHit;
					PostImpactEvent(TrackedTransform);
				}

			TrackedTransform.LastPosition = Transform.Translation;
		}

		++CurrentIndex;
		if (CurrentIndex >= SocketsToTrack.Num())
			CurrentIndex = 0;
	}

	void PostImpactEvent(FTrackedTransform& TrackedTransform) 
	{
		ERagdollBodyPart BodyPart = ERagdollBodyPart(CurrentIndex);
		FRagdollAudioEvent Event;
		FString Rtpc;
		float RetriggerIncrease = 0;
		GetData(BodyPart, Event, Rtpc, RetriggerIncrease);

		FVector IntensityVector = PrimitiveComp.GetPhysicsLinearVelocity(SocketsToTrack[CurrentIndex]);
		float CurrentIntensity = IntensityVector.Size();
		
		if (TrackedTransform.Timer <= 0 ||
			(CurrentIntensity > (TrackedTransform.LastIntensity * RetriggerIncrease)))
		{
			// Print("" + SocketsToTrack[CurrentIndex] + ", Intensity: " 
			// 		+ CurrentIntensity + ", Hit: " 
			// 		+ TrackedTransform.LastHit.Component.Owner);
			// Print("LastIntensity: " + TrackedTransform.LastIntensity);

			//System::DrawDebugPoint(TrackedTransform.LastHit.ImpactPoint, 10, FLinearColor::Green, 10);
			ActiveImpacts.AddUnique(CurrentIndex);
			TrackedTransform.Timer = Event.Cooldown;
			TrackedTransform.LastIntensity = CurrentIntensity;
			TrackedTransform.LastVelocity = IntensityVector;

			float RtpcValue = Math::GetPercentageBetweenClamped(Event.RtpcMinValue, Event.RtpcMaxValue, CurrentIntensity);
			
			Player.PlayerHazeAkComp.SetRTPCValue(Rtpc, RtpcValue);
			Player.PlayerHazeAkComp.HazePostEvent(Event.ImpactEvent);
		}
	}

	void GetData(ERagdollBodyPart BodyPart, FRagdollAudioEvent& Event, FString& Rtpc, float& RetriggerIncrease)
	{
		FRagdollAudioEvents& Container = Player.IsMay() ? MayAudioEvents : CodyAudioEvents;

		switch (BodyPart)
		{
			case ERagdollBodyPart::Head:
			Event = Container.HeadImpactEvent;
			Rtpc = HeadImpactRtpc;
			break;
			case ERagdollBodyPart::Body:
			Event = Container.BodyImpactEvent;
			Rtpc = BodyImpactRtpc;
			break;
			case ERagdollBodyPart::LeftArm:
			case ERagdollBodyPart::RighArm:
			Event = Container.HandArmImpactEvent;
			Rtpc = HandArmImpactRtpc;
			break;
			case ERagdollBodyPart::LeftLeg:
			case ERagdollBodyPart::RightLeg:
			Event = Container.FootLegImpactEvent;
			Rtpc = FootLegImpactRtpc;
			break;
		}

		RetriggerIncrease = Container.IntensityIncreaseToRetrigger;
	}
};