import Peanuts.Audio.AudioStatics;
import Vino.Audio.Movement.PlayerMovementAudioComponent;

class FPlayerMovementAudioEventData : UDataAsset
{
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
	FEffortEvents EffortEvents;

	UPROPERTY()
	FGrindingEvents GrindingEvents;
	
	UPROPERTY()
	FArmBodyMovementEvents ArmBodyMovementEvents;

	UPROPERTY()
	FJumpEvents JumpEvents;

	UPROPERTY()
	FFallingSkydivingEvents FallingSkydivingEvents;

	UPROPERTY()
	UPhysicalMaterialAudio DefaultPhysAudioAsset;

	UFUNCTION()
	UAkAudioEvent GetDefaultFootstepEvent(
		HazeAudio::EPlayerFootstepType FootstepType, 
		HazeAudio::EMaterialFootstepType MaterialType, 
		HazeAudio::EMaterialSlideType SlideType)
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
}	