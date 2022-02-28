import Peanuts.Audio.AudioStatics;

import Vino.Movement.Components.MovementComponent;
import Vino.Audio.Footsteps.FootstepStatics;

class UFootstepComponent : UActorComponent
{
	/** Tag used for finding footstep audio. */
	UPROPERTY()
	FName FootstepTag;

	/** Whether to automatically trigger footsteps when traces detect that a foot has hit the ground. */
	UPROPERTY()
	bool bAutoTriggerFootsteps = false;

	/** Bones to use for automatically triggering footsteps. */
	UPROPERTY(Meta = (EditCondition = "bAutoTriggerFootsteps", EditConditionHides))
	TArray<FName> FootBones;
	default FootBones.Add(n"LeftFoot");
	default FootBones.Add(n"RightFoot");

	/** Trigger distance in cm from the floor to consider a foot to be planted. */
	UPROPERTY(Meta = (EditCondition = "bAutoTriggerFootsteps", EditConditionHides))
	float FootstepTriggerMargin = 10.f;

	/** Default footstep when the floor does not have anything configured for this tag. */
	UPROPERTY(EditAnywhere, Category = "Parameters")
	UAkAudioEvent DefaultFootstep;	

	// Whether the foot is currently planted on the floor
	private TArray<bool> FootOnFloor;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		int FootCount = FootBones.Num();
		FootOnFloor.SetNum(FootCount);

		for (int i = 0; i < FootCount; ++i)
			FootOnFloor[i] = true;

		PlayerOwner = Cast<AHazePlayerCharacter>(GetOwner());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{		
		UHazeSkeletalMeshComponentBase MeshComp = UHazeSkeletalMeshComponentBase::Get(Owner);
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Owner);

		// Update the position for all foot bones
		int FootCount = FootBones.Num();
		FTransform ActorTransform = Owner.ActorTransform;
		for (int i = 0; i < FootCount; ++i)
		{
			FName Bone = FootBones[i];
			FTransform BoneTransform = MeshComp.GetSocketTransform(Bone, ERelativeTransformSpace::RTS_Actor);
			FFootstepTrace Trace;

			bool bGrounded = false;
			if (MoveComp != nullptr)
			{
				bGrounded = MoveComp.IsGrounded();
				GetFootstepTraceFromMovementComponent(MoveComp, Trace);
			}
			else
			{
				// Perform a trace since the movement component isn't doing it
				FVector FootWorldPos = ActorTransform.TransformPosition(BoneTransform.Location);

				auto HazeOwner = Cast<AHazeActor>(Owner);
				FVector WorldUp = FVector::UpVector;
				if (HazeOwner != nullptr)
					WorldUp = HazeOwner.MovementWorldUp;

				PerformFootstepTrace(
					FootWorldPos,
					FootWorldPos + WorldUp * -FootstepTriggerMargin,
					Trace);
				bGrounded = Trace.bGrounded;
			}

			bool bWasOnFloor = FootOnFloor[i];
			bool bCurrentlyOnFloor = bGrounded && BoneTransform.Location.Z <= FootstepTriggerMargin;
			FootOnFloor[i] = bCurrentlyOnFloor;

			if (bCurrentlyOnFloor && !bWasOnFloor)
			{
				float MovementSpeed =  Owner.ActorVelocity.Size();

				// Trigger a footstep sound
				UAkAudioEvent Event;
				if (Trace.PhysAudio != nullptr)
					Event = Trace.PhysAudio.GetMaterialFootstep(PlayerOwner).AudioEvent;
				if (Event == nullptr)
					Event = DefaultFootstep;

				if (Event != nullptr)
				{
					UHazeAkComponent HazeAkComp = HazeAudio::SpawnAkCompAtLocation(Event, Owner);
					HazeAkComp.SetWorldLocation(Owner.ActorTransform.TransformPosition(BoneTransform.Location));
					HazeAkComp.HazePostEvent(Event);
					//HazeAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterMovementSpeed, MovementSpeed, 0);
				}
			}
		}
	}
};
