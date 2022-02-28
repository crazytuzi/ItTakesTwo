import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;
import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;
import Vino.Audio.Movement.PlayerMovementAudioComponent;
import Peanuts.Audio.AudioStatics;
import Vino.Movement.MovementSystemTags;

class UCharacterWallSlideAudioCapability : UHazeCapability
{
	UHazeAkComponent HazeAkComp;
	UHazeMovementComponent MoveComp;
	UPlayerMovementAudioComponent AudioMoveComp;
	UCharacterWallSlideComponent WallSlideComp;
	FAudioPhysMaterial AudioPhysMat;
	UPhysicalMaterialAudio AudioMaterial;
	UAkAudioEvent SlideTypeEvent;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::WallSlide);
	default CapabilityTags.Add(CapabilityTags::MovementAction);

	default TickGroup = ECapabilityTickGroups::GamePlay;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		WallSlideComp = UCharacterWallSlideComponent::Get(Owner);
		HazeAkComp = UHazeAkComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		AudioMoveComp = UPlayerMovementAudioComponent::GetOrCreate(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!WallSlideComp.IsSliding())		
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UPhysicalMaterial PhysMat = MoveComp.GetContactSurfaceMaterial();	

		if(PhysMat != nullptr)
		{
			AudioMaterial = Cast<UPhysicalMaterialAudio>(PhysMat.AudioAsset);
			if(AudioMaterial != nullptr)
			{		
				AudioPhysMat = AudioMaterial.GetMaterialInteractionEvent(Cast<AHazePlayerCharacter>(Owner), HazeAudio::EPlayerFootstepType::FootSlide);	

				if(AudioPhysMat.AudioEvent != nullptr)
				{
					HazeAkComp.HazePostEvent(AudioPhysMat.AudioEvent);
				}
			}
	
			SlideTypeEvent = AudioMoveComp.GetDefaultFootstepEvent(HazeAudio::EPlayerFootstepType::FootSlide, AudioPhysMat.MaterialType, AudioPhysMat.SlideType);

			if(SlideTypeEvent != nullptr)
			{
				HazeAkComp.HazePostEvent(SlideTypeEvent);
			}

			SlideTypeEvent = AudioMoveComp.GetDefaultFootstepEvent(HazeAudio::EPlayerFootstepType::FootSlideLoop, AudioPhysMat.MaterialType, AudioPhysMat.SlideType);

			if(SlideTypeEvent != nullptr)
			{
				HazeAkComp.HazePostEvent(SlideTypeEvent);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!WallSlideComp.IsSliding())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateLocal;		
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{	
		if(AudioMaterial != nullptr)
		{
			AudioPhysMat = AudioMaterial.GetMaterialInteractionEvent(Cast<AHazePlayerCharacter>(Owner), HazeAudio::EPlayerFootstepType::FootSlide);	
			SlideTypeEvent = AudioMoveComp.GetDefaultFootstepEvent(HazeAudio::EPlayerFootstepType::FootSlideStop, AudioPhysMat.MaterialType, AudioPhysMat.SlideType);
		}
		else
		{	
			AudioPhysMat = AudioMoveComp.GetDefaultPhysAudioInteractionMaterial(Cast<AHazePlayerCharacter>(Owner), HazeAudio::EPlayerFootstepType::FootSlide);
			SlideTypeEvent = AudioMoveComp.GetDefaultFootstepEvent(HazeAudio::EPlayerFootstepType::FootSlideStop, AudioPhysMat.MaterialType, AudioPhysMat.SlideType);
		}

		if(SlideTypeEvent != nullptr)
		{
			HazeAkComp.HazePostEvent(SlideTypeEvent);
		}

		if(WallSlideComp.FootSlideStopEvent != nullptr)
		{
			HazeAkComp.HazePostEvent(WallSlideComp.FootSlideStopEvent);
		}
		
	}
}
