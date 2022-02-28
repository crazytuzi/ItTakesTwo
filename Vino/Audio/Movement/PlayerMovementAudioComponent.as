import Peanuts.Audio.AudioStatics;
import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;
import Vino.Movement.Components.MovementComponent;

struct FRunEvents
{
	UPROPERTY()
	UAkAudioEvent DefaultRunSoftFootstepEvent;

	UPROPERTY()
	UAkAudioEvent DefaultRunHardFootstepEvent;
};

struct FCrouchEvents
{
	UPROPERTY()
	UAkAudioEvent DefaultCrouchSoftFootstepEvent;

	UPROPERTY()
	UAkAudioEvent DefaultCrouchHardFootstepEvent;
};

struct FScuffEvents
{
	UPROPERTY()
	UAkAudioEvent DefaultScuffLowIntensitySoftEvent;

	UPROPERTY()
	UAkAudioEvent DefaultScuffLowIntensityHardEvent;

	UPROPERTY()
	UAkAudioEvent DefaultScuffHighIntensitySoftEvent;

	UPROPERTY()
	UAkAudioEvent DefaultScuffHighIntensityHardEvent;
};

struct FSprintEvents
{
	UPROPERTY()
	UAkAudioEvent DefaultSprintSoftFootstepEvent;

	UPROPERTY()
	UAkAudioEvent DefaultSprintHardFootstepEvent;
};

struct FHandsEvent
{
	UPROPERTY()
	UAkAudioEvent DefaultHandsImpactHighIntensitySoftMaterialEvent;

	UPROPERTY()
	UAkAudioEvent DefaultHandsImpactHighIntensityHardMaterialEvent;

	UPROPERTY()
	UAkAudioEvent DefaultHandsImpactLowIntensitySoftMaterialEvent;

	UPROPERTY()
	UAkAudioEvent DefaultHandsImpactLowIntensityHardMaterialEvent;

	UPROPERTY()
	UAkAudioEvent DefaultHandsScuffSoftMaterialEvent;

	UPROPERTY()
	UAkAudioEvent DefaultHandsScuffHardMaterialEvent;

};	

struct FBodyMovementEvents
{
	UPROPERTY()
	UAkAudioEvent DefaultBodyMovementEvent;
	
};

struct FLandingEvents
{
	UPROPERTY()
	UAkAudioEvent LandingLowIntensity;

	UPROPERTY()
	UAkAudioEvent LandingHighIntensity;
}

struct FSlidingEvents
{
	UPROPERTY()
	UAkAudioEvent FootSlideSmoothStartEvent;

	UPROPERTY()
	UAkAudioEvent FootSlideRoughStartEvent;

	UPROPERTY()
	UAkAudioEvent FootSlideSmoothStopEvent;

	UPROPERTY()
	UAkAudioEvent FootSlideRoughStopEvent;

	UPROPERTY()
	UAkAudioEvent FootSlideSmoothLoopEvent;

	UPROPERTY()
	UAkAudioEvent FootSlideRoughLoopEvent;

	UPROPERTY()
	UAkAudioEvent AssSlideSmoothStartEvent;

	UPROPERTY()
	UAkAudioEvent AssSlideRoughStartEvent;

	UPROPERTY()
	UAkAudioEvent AssSlideSmoothStartLoopEvent;

	UPROPERTY()
	UAkAudioEvent AssSlideRoughStartLoopEvent;

	UPROPERTY()
	UAkAudioEvent AssSlideSmoothStopEvent;

	UPROPERTY()
	UAkAudioEvent AssSlideRoughStopEvent;
}

struct FGrindingEvents
{
	UPROPERTY()
	UAkAudioEvent DefaultGrindingLoopEvent;	

	UPROPERTY()
	UAkAudioEvent DefaultGrindingDismountEvent;

	UPROPERTY()
	UAkAudioEvent DefaultGrappleAttachEvent;

	UPROPERTY()
	UAkAudioEvent DefaultGrappleDettachEvent;

	UPROPERTY()
	UAkAudioEvent DefaultGrindingPassbyEvent;

	UPROPERTY()
	float DefaultGrindingPassbyEventApexTime = 0.3;
}

struct FFallingSkydivingEvents
{
	UPROPERTY()
	UAkAudioEvent StartFallingEvent;

	UPROPERTY()
	UAkAudioEvent StopFallingEvent;

	UPROPERTY()
	UAkAudioEvent StartSkydivingEvent;

	UPROPERTY()
	UAkAudioEvent StopSkydivingEvent;
}

struct FArmBodyMovementEvents
{
	UPROPERTY()
	UAkAudioEvent ArmFastEvent;

	UPROPERTY()
	UAkAudioEvent ArmSlowEvent;

	UPROPERTY()
	UAkAudioEvent BodyHighIntensityEvent;

	UPROPERTY()
	UAkAudioEvent BodyLowIntensityEvent;
}

struct FJumpEvents
{
	UPROPERTY()
	UAkAudioEvent JumpEvents;

}

struct FEffortEvents
{
	UPROPERTY()
	UAkAudioEvent EffortBreathRunDefaultEvents;

	UPROPERTY()
	UAkAudioEvent EffortBreathSkyDiveStartEvents;

	UPROPERTY()
	UAkAudioEvent EffortBreathSkyDiveStopEvents;

}


class UPlayerMovementAudioComponent : USceneComponent
{
	AHazePlayerCharacter Player;	
	UPlayerHazeAkComponent HazeAkComp;
	UHazeMovementComponent MoveComp;

	UPROPERTY(NotVisible)
	UAkAudioEvent BodyMovementEvent;	

	UPROPERTY(NotVisible)
	FHazeAudioEventInstance BodyMovementEventInstance;

	UPROPERTY()
	FBodyMovementEvents BodyMovementEvents;

	UPROPERTY()
	FCrouchEvents CrouchEvents;

	UPROPERTY()
	FScuffEvents ScuffEvents;

	UPROPERTY()
	FRunEvents RunEvents;

	UPROPERTY()
	FSprintEvents SprintEvents;

	UPROPERTY()
	FHandsEvent HandEvents;

	UPROPERTY()
	FLandingEvents LandingEvents;

	UPROPERTY()
	FSlidingEvents SlidingEvents;

	UPROPERTY()
	FJumpEvents JumpEvents;

	UPROPERTY()
	FEffortEvents EffortEvents;

	UPROPERTY()
	FGrindingEvents GrindingEvents;

	UPROPERTY()
	FFallingSkydivingEvents FallingSkydivingEvents;

	UPROPERTY()
	FArmBodyMovementEvents ArmBodyMovementEvents;

	UPROPERTY()
	UPhysicalMaterialAudio DefaultPhysAudioAsset;

	bool bSeekOnBodyMovement = false;
	private bool bCanUpdateTraversalType = true;

	UAkAudioEvent OverrideFootstepEvent = nullptr;
	UPhysicalMaterialAudio GrindingOverrideAudioPhysmat = nullptr;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);		
		MoveComp = UHazeMovementComponent::Get(Owner);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner, n"PlayerHazeAkComponent");
		HazeAkComp.SetStopWhenOwnerDestroyed(true);			
	}

	UFUNCTION()
	void StopMovementEvent(int BodyMovementPlayingID, int EffortPlayingID)
	{			
		HazeAkComp.HazeStopEvent(BodyMovementPlayingID);
		HazeAkComp.HazeStopEvent(EffortPlayingID);
	}

	UFUNCTION()
	void UpdateBodyMovementEvent(UAkAudioEvent InBodyMovementEvent)
	{
		if(BodyMovementEventInstance.PlayingID != 0)
			HazeAkComp.HazeStopEvent(BodyMovementEventInstance.PlayingID, 1000.f);

		BodyMovementEventInstance = HazeAkComp.HazePostEvent(InBodyMovementEvent);
		BodyMovementEvent = InBodyMovementEvent;
	}
	
	UFUNCTION()
	bool PerformSkydiveTrace()
	{
		FHazeHitResult TraceHit;
		FHazeTraceParams SkydiveTrace;
		SkydiveTrace.InitWithMovementComponent(MoveComp);	
		SkydiveTrace.SetToLineTrace();

		SkydiveTrace.From = Player.GetActorCenterLocation();
		float TraceDistance = -3500.f;

		SkydiveTrace.To = SkydiveTrace.From + (MoveComp.WorldUp * TraceDistance);			
		SkydiveTrace.Trace(TraceHit);

		if(TraceHit.bBlockingHit)
		{
			float SkydiveRtpcValue = TraceHit.Distance / TraceDistance;		
			HazeAkComp.SetRTPCValue(HazeAudio::RTPC::CharacterSkydiveDistanceToGround, FMath::Abs(SkydiveRtpcValue));
			return true;	
		}

		return false;
	}

	UFUNCTION()
	void SetTraversalTypeSwitch(HazeAudio::EPlayerMovementState TraversalType)
	{
		if(!bCanUpdateTraversalType)
			return;

		switch(TraversalType)
		{
			case HazeAudio::EPlayerMovementState::Idle:
				HazeAkComp.SetSwitch(HazeAudio::SWITCH::PlayerTraversalTypeSwitchGroup, HazeAudio::SWITCH::PlayerTraversalTypeIdle);
				HazeAkComp.SetRTPCValue("Rtpc_Player_Traversal_Type", 0);
				break;			
			case HazeAudio::EPlayerMovementState::Crouch:
				HazeAkComp.SetSwitch(HazeAudio::SWITCH::PlayerTraversalTypeSwitchGroup, HazeAudio::SWITCH::PlayerTraversalTypeCrouch);
				HazeAkComp.SetRTPCValue("Rtpc_Player_Traversal_Type", 1);
				break;
			case HazeAudio::EPlayerMovementState::Run:
				HazeAkComp.SetSwitch(HazeAudio::SWITCH::PlayerTraversalTypeSwitchGroup, HazeAudio::SWITCH::PlayerTraversalTypeRun);
				HazeAkComp.SetRTPCValue("Rtpc_Player_Traversal_Type", 2);
				break;
			case HazeAudio::EPlayerMovementState::Sprint:
				HazeAkComp.SetSwitch(HazeAudio::SWITCH::PlayerTraversalTypeSwitchGroup, HazeAudio::SWITCH::PlayerTraversalTypeSprint);
				HazeAkComp.SetRTPCValue("Rtpc_Player_Traversal_Type", 3);
				break;
			case HazeAudio::EPlayerMovementState::Slide:
				HazeAkComp.SetSwitch(HazeAudio::SWITCH::PlayerTraversalTypeSwitchGroup, HazeAudio::SWITCH::PlayerTraversalTypeSlide);
				HazeAkComp.SetRTPCValue("Rtpc_Player_Traversal_Type", 5);
				break;
			case HazeAudio::EPlayerMovementState::Grind:
				HazeAkComp.SetSwitch(HazeAudio::SWITCH::PlayerTraversalTypeSwitchGroup, HazeAudio::SWITCH::PlayerTraversalTypeGrind);
				HazeAkComp.SetRTPCValue("Rtpc_Player_Traversal_Type", 6);
				break;
			case HazeAudio::EPlayerMovementState::HeavyWalk:
				HazeAkComp.SetSwitch(HazeAudio::SWITCH::PlayerTraversalTypeSwitchGroup, HazeAudio::SWITCH::PlayerTraversalTypeHeavyWalk);
				HazeAkComp.SetRTPCValue("Rtpc_Player_Traversal_Type", 4);
				break;
			case HazeAudio::EPlayerMovementState::Falling:
				HazeAkComp.SetSwitch(HazeAudio::SWITCH::PlayerTraversalTypeSwitchGroup, HazeAudio::SWITCH::PlayerTraversalTypeFalling);
				HazeAkComp.SetRTPCValue("Rtpc_Player_Traversal_Type", 7);
				break;
			case HazeAudio::EPlayerMovementState::Skydive:
				HazeAkComp.SetSwitch(HazeAudio::SWITCH::PlayerTraversalTypeSwitchGroup, HazeAudio::SWITCH::PlayerTraversalTypeSkydive);
				HazeAkComp.SetRTPCValue("Rtpc_Player_Traversal_Type", 8);
				break;
			case HazeAudio::EPlayerMovementState::Swimming:
				HazeAkComp.SetSwitch(HazeAudio::SWITCH::PlayerTraversalTypeSwitchGroup, HazeAudio::SWITCH::PlayerTraversalTypeSwimming);
				HazeAkComp.SetRTPCValue("Rtpc_Player_Traversal_Type", 9);
				break;
			case HazeAudio::EPlayerMovementState::Swing:
				HazeAkComp.SetSwitch(HazeAudio::SWITCH::PlayerTraversalTypeSwitchGroup, HazeAudio::SWITCH::PlayerTraversalTypeSwing);
				HazeAkComp.SetRTPCValue("Rtpc_Player_Traversal_Type", 10);
				break;
			case HazeAudio::EPlayerMovementState::IceSkating:
				HazeAkComp.SetSwitch(HazeAudio::SWITCH::PlayerTraversalTypeSwitchGroup, HazeAudio::SWITCH::PlayerTraversalTypeIceSkating);
				HazeAkComp.SetRTPCValue("Rtpc_Player_Traversal_Type", 11);
				break;
			default:
				break;
		}		
	}

	UFUNCTION()
	UAkAudioEvent GetDefaultFootstepEvent(HazeAudio::EPlayerFootstepType FootstepType, HazeAudio::EMaterialFootstepType MaterialType, HazeAudio::EMaterialSlideType SlideType)
	{
		switch(FootstepType)
		{
			case HazeAudio::EPlayerFootstepType::Run:
				switch(MaterialType)
				{
					case HazeAudio::EMaterialFootstepType::Soft:
						return RunEvents.DefaultRunSoftFootstepEvent;	
					case HazeAudio::EMaterialFootstepType::Hard:
						return RunEvents.DefaultRunHardFootstepEvent;
					default:
						return nullptr;
				}

			case HazeAudio::EPlayerFootstepType::Crouch:
				switch(MaterialType)
				{
					case HazeAudio::EMaterialFootstepType::Soft:
						return CrouchEvents.DefaultCrouchSoftFootstepEvent;	
					case HazeAudio::EMaterialFootstepType::Hard:
						return CrouchEvents.DefaultCrouchHardFootstepEvent;
					default:
						return nullptr;
				}
				
			case HazeAudio::EPlayerFootstepType::Sprint:
				switch(MaterialType)
				{
					case HazeAudio::EMaterialFootstepType::Soft:
						return SprintEvents.DefaultSprintSoftFootstepEvent;	
					case HazeAudio::EMaterialFootstepType::Hard:
						return SprintEvents.DefaultSprintHardFootstepEvent;
					default:
						return nullptr;
				}	

			case HazeAudio::EPlayerFootstepType::ScuffLowIntensity:
				switch(MaterialType)
				{
					case HazeAudio::EMaterialFootstepType::Soft:
						return ScuffEvents.DefaultScuffLowIntensitySoftEvent;
					case HazeAudio::EMaterialFootstepType::Hard:
						return ScuffEvents.DefaultScuffLowIntensityHardEvent;
					default:
						return nullptr;
				}
			case HazeAudio::EPlayerFootstepType::ScuffHighIntensity:
				switch(MaterialType)
				{
					case HazeAudio::EMaterialFootstepType::Soft:
						return ScuffEvents.DefaultScuffHighIntensitySoftEvent;
					case HazeAudio::EMaterialFootstepType::Hard:
						return ScuffEvents.DefaultScuffHighIntensityHardEvent;
				}

			case HazeAudio::EPlayerFootstepType::HandsImpactLowIntensity:
				switch(MaterialType)
				{
					case HazeAudio::EMaterialFootstepType::Soft:
						return HandEvents.DefaultHandsImpactLowIntensitySoftMaterialEvent;
					case HazeAudio::EMaterialFootstepType::Hard:
						return HandEvents.DefaultHandsImpactLowIntensityHardMaterialEvent;
				}

			case HazeAudio::EPlayerFootstepType::HandsImpactHighIntensity:
				switch(MaterialType)
				{
					case HazeAudio::EMaterialFootstepType::Soft:
						return HandEvents.DefaultHandsImpactHighIntensitySoftMaterialEvent;
					case HazeAudio::EMaterialFootstepType::Hard:
						return HandEvents.DefaultHandsImpactHighIntensityHardMaterialEvent;
				}
			case HazeAudio::EPlayerFootstepType::HandScuff:
				switch(MaterialType)
				{
					case HazeAudio::EMaterialFootstepType::Soft:
						return HandEvents.DefaultHandsScuffSoftMaterialEvent;
					case HazeAudio::EMaterialFootstepType::Hard:
						return HandEvents.DefaultHandsScuffHardMaterialEvent;
				}
			case HazeAudio::EPlayerFootstepType::LandingLowIntensity:
				return LandingEvents.LandingLowIntensity;

			case HazeAudio::EPlayerFootstepType::LandingHighIntensity:
				return LandingEvents.LandingHighIntensity;

			case HazeAudio::EPlayerFootstepType::FootSlide:
				switch(SlideType)
				{
					case HazeAudio::EMaterialSlideType::Smooth:
						return SlidingEvents.FootSlideSmoothStartEvent;
					case HazeAudio::EMaterialSlideType::Rough:
						return SlidingEvents.FootSlideRoughStartEvent;
				}

			case HazeAudio::EPlayerFootstepType::FootSlideStop:
				switch(SlideType)
				{
					case HazeAudio::EMaterialSlideType::Smooth:
						return SlidingEvents.FootSlideSmoothStopEvent;
					case HazeAudio::EMaterialSlideType::Rough:
						return SlidingEvents.FootSlideRoughStopEvent;
				}

			case HazeAudio::EPlayerFootstepType::FootSlideLoop:
				switch(SlideType)
				{
					case HazeAudio::EMaterialSlideType::Smooth:
						return SlidingEvents.FootSlideSmoothLoopEvent;
					case HazeAudio::EMaterialSlideType::Rough:
						return SlidingEvents.FootSlideRoughLoopEvent;
				}

			case HazeAudio::EPlayerFootstepType::AssSlide:
				switch(SlideType)
				{
					case HazeAudio::EMaterialSlideType::Smooth:
						return SlidingEvents.AssSlideSmoothStartEvent;
					case HazeAudio::EMaterialSlideType::Rough:
						return SlidingEvents.AssSlideRoughStartEvent;
				}

			case HazeAudio::EPlayerFootstepType::AssSlideLoop:
			switch(SlideType)
			{
				case HazeAudio::EMaterialSlideType::Smooth:
					return SlidingEvents.AssSlideSmoothStartLoopEvent;
				case HazeAudio::EMaterialSlideType::Rough:
					return SlidingEvents.AssSlideRoughStartLoopEvent;
			}

			case HazeAudio::EPlayerFootstepType::AssSlideStop:
				switch(SlideType)
				{
					case HazeAudio::EMaterialSlideType::Smooth:
						return SlidingEvents.AssSlideSmoothStopEvent;
					case HazeAudio::EMaterialSlideType::Rough:
						return SlidingEvents.AssSlideRoughStopEvent;
				}				

			case HazeAudio::EPlayerFootstepType::ArmFast:
				return ArmBodyMovementEvents.ArmFastEvent;

			case HazeAudio::EPlayerFootstepType::ArmSlow:
				return ArmBodyMovementEvents.ArmSlowEvent;

			case HazeAudio::EPlayerFootstepType::BodyHighInt:
				return ArmBodyMovementEvents.BodyHighIntensityEvent;

			case HazeAudio::EPlayerFootstepType::BodyLowInt:
				return ArmBodyMovementEvents.BodyLowIntensityEvent;

			case HazeAudio::EPlayerFootstepType::Jump:
				return JumpEvents.JumpEvents;

			default:
				return nullptr;
		}

		return nullptr;
	}

	UFUNCTION()
	FAudioPhysMaterial GetDefaultPhysAudioInteractionMaterial(AHazePlayerCharacter Player, HazeAudio::EPlayerFootstepType InteractionType)
	{
		FAudioPhysMaterial FootstepMaterial;
		if (!ensure(DefaultPhysAudioAsset != nullptr))
			return FootstepMaterial;

		FootstepMaterial.MaterialType = DefaultPhysAudioAsset.MaterialType;
		FootstepMaterial.SlideType = DefaultPhysAudioAsset.SlideType;

		if(Player.IsMay())
		{
			switch(InteractionType)
			{
				case HazeAudio::EPlayerFootstepType::Run:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.MayMaterialEvents.MayMaterialFootstepEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::Crouch:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.MayMaterialEvents.MayMaterialFootstepEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::Sprint:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.MayMaterialEvents.MayMaterialFootstepEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::ScuffLowIntensity:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.MayMaterialEvents.MayMaterialScuffEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::ScuffHighIntensity:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.MayMaterialEvents.MayMaterialScuffEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::HandScuff:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.MayMaterialEvents.MayMaterialHandScuffEvent;	
					return FootstepMaterial;							
				case HazeAudio::EPlayerFootstepType::HandsImpactLowIntensity:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.MayMaterialEvents.MayMaterialHandEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::HandsImpactHighIntensity:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.MayMaterialEvents.MayMaterialHandEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::LandingLowIntensity:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.MayMaterialEvents.MayMaterialLandEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::LandingHighIntensity:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.MayMaterialEvents.MayMaterialLandEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::FootSlide:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.MayMaterialEvents.MayMaterialFootSlideEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::HandSlide:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.MayMaterialEvents.MayMaterialHandSlideEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::AssSlide:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.MayMaterialEvents.MayMaterialAssSlideEvent;
					return FootstepMaterial;
									
				default:
					return FootstepMaterial;				
			}			
		}
		else
		{
			switch(InteractionType)
			{
				case HazeAudio::EPlayerFootstepType::Run:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.CodyMaterialEvents.CodyMaterialFootstepEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::Crouch:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.CodyMaterialEvents.CodyMaterialFootstepEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::Sprint:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.CodyMaterialEvents.CodyMaterialFootstepEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::ScuffLowIntensity:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.CodyMaterialEvents.CodyMaterialScuffEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::ScuffHighIntensity:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.CodyMaterialEvents.CodyMaterialScuffEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::HandScuff:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.CodyMaterialEvents.CodyMaterialHandScuffEvent;
					return FootstepMaterial;												
				case HazeAudio::EPlayerFootstepType::HandsImpactLowIntensity:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.CodyMaterialEvents.CodyMaterialHandEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::HandsImpactHighIntensity:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.CodyMaterialEvents.CodyMaterialHandEvent;
					return FootstepMaterial;			
					case HazeAudio::EPlayerFootstepType::LandingLowIntensity:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.CodyMaterialEvents.CodyMaterialLandEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::LandingHighIntensity:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.CodyMaterialEvents.CodyMaterialLandEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::FootSlide:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.CodyMaterialEvents.CodyMaterialFootSlideEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::HandSlide:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.CodyMaterialEvents.CodyMaterialHandSlideEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::AssSlide:
					FootstepMaterial.AudioEvent = DefaultPhysAudioAsset.CodyMaterialEvents.CodyMaterialAssSlideEvent;
					return FootstepMaterial;
				default:
					return FootstepMaterial;
			}
			
		}

		return FootstepMaterial;
	}	

	UFUNCTION(BlueprintCallable)
	void SetCanUpdateTraversalType(bool bCanUpdate)
	{
		bCanUpdateTraversalType = bCanUpdate;
	}
}