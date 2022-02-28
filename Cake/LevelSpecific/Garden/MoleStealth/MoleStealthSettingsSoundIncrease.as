import Cake.LevelSpecific.Garden.MoleStealth.MoleStealthSettings;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;

import bool CanGroundPoundIntoSneakyBush(AHazePlayerCharacter) from "Cake.LevelSpecific.Garden.ControllablePlants.SneakyBush.SneakyBush";

// SETTINGS
namespace MoleStealthSettings
{
	// How much to increase the values from the types
	float GetVolumeIncreaseAmount(EMoleStealthDetectionSoundVolume SoundType, float DeltaTime, AHazePlayerCharacter Player)
	{
		const bool bIsGroundPunding =  UCharacterGroundPoundComponent::Get(Player).IsGroundPounding();
		const bool bGroundPoundLanded = UCharacterGroundPoundComponent::Get(Player).LandedThisFrame();

		// This is a safe spot
		if(bIsGroundPunding)
		{
			if(CanGroundPoundIntoSneakyBush(Player))
				return 0;
		}

		// Get the sound modifier amount
		const float Multiplier = GetMultiplier(
			SoundType,
			DeltaTime,
			UHazeBaseMovementComponent::Get(Player),
			Player.IsAnyCapabilityActive(MovementSystemTags::Crouch),
			bGroundPoundLanded,
			Player.IsAnyCapabilityActive(MovementSystemTags::Sprint),
			Player.IsAnyCapabilityActive(MovementSystemTags::Dash)	
		);
	
		float WantedVolume = 0.f;

		switch(SoundType)
		{
			// Null
			case EMoleStealthDetectionSoundVolume::Null:
				WantedVolume = 0.0f;
				break;

			// NONE (Also applies if not inside any sound volumes)
			case EMoleStealthDetectionSoundVolume::None:
				WantedVolume = 0.75f;
				break;

			// LOW
			case EMoleStealthDetectionSoundVolume::Low:
				WantedVolume = 3.0f;
				break;

			// NORMAL
			case EMoleStealthDetectionSoundVolume::Normal:
				WantedVolume = 5.45f;
				break;

			// HIGH
			case EMoleStealthDetectionSoundVolume::High:
				WantedVolume = 12.0f;
				break;

			// INSTANT DEATH
			case EMoleStealthDetectionSoundVolume::InstantDeath:
				WantedVolume = 15.0f;
				break;
		}

		// Finalize the sound
		return WantedVolume * Multiplier;
	}

	float GetMultiplier(EMoleStealthDetectionSoundVolume SoundType, float DeltaTime, UHazeBaseMovementComponent MoveComp, bool bIsCrouching, bool bIsGroundPunding, bool bIsSprinting, bool bIsDashing)
	{
		// Groundpounding Safe spot
		if(SoundType == EMoleStealthDetectionSoundVolume::None && bIsGroundPunding)
		{
			//Print("GroundPounded", 2.0f);
			// Skip the delta time and use a fast value for 1 frame
			return 3200 * (1.f / 30.f);
		}
		// Groundpounding
		else if(SoundType != EMoleStealthDetectionSoundVolume::None && bIsGroundPunding)
		{
			//Print("GroundPounded", 2.0f);
			// Skip the delta time and use a fast value for 1 frame
			return 9001 * (1.f / 30.f); // Over nine thousand!
		}

		// Crouching Standing still
		else if(SoundType != EMoleStealthDetectionSoundVolume::None && bIsCrouching && MoveComp.Velocity.SizeSquared() < 1)
		{
			//Print("Crouching Still");
			return 5.f * DeltaTime;
		}
		// Crouching Standing still
		else if(SoundType == EMoleStealthDetectionSoundVolume::None && bIsCrouching && MoveComp.Velocity.SizeSquared() < 1)
		{
			//Print("Crouching Still safe");
			return 0;
		}

		// Crouching Moving in safe spot
		else if(SoundType == EMoleStealthDetectionSoundVolume::None && bIsCrouching)
		{
			//Print("Crouching Safe");
			return 0.0f;
		}
		// Crouching Moving
		else if(SoundType != EMoleStealthDetectionSoundVolume::None && bIsCrouching)
		{
			//Print("Crouching Moving");
			return 5.f * DeltaTime;
		}

		// Landing null spot
		else if(SoundType == EMoleStealthDetectionSoundVolume::Null && MoveComp.BecameGrounded())
		{
			//Print("Landed null spot", 2.0f);
			return 0.f;
		}	
		// Landing safe spot
		else if(SoundType == EMoleStealthDetectionSoundVolume::None && MoveComp.BecameGrounded())
		{
			//Print("Landed safe spot", 2.0f);
			// Skip the delta time and use a fast value for 1 frame
			return 450.f  * (1.f / 30.f);
		}
		// Landing 
		else if(SoundType != EMoleStealthDetectionSoundVolume::None && MoveComp.BecameGrounded())
		{	
			//Print("Landed", 2.0f);
			// Skip the delta time and use a fast value for 1 frame
			return 200.f * (1.f / 30.f);
		}

		// StandingStill safe spot
		else if(SoundType == EMoleStealthDetectionSoundVolume::None && MoveComp.Velocity.SizeSquared() < 1)
		{
			//Print("StandingStill safe spot");
			return 0.f;
		}	
		// StandingStill
		else if(SoundType != EMoleStealthDetectionSoundVolume::None && MoveComp.Velocity.SizeSquared() < 1)
		{
			//Print("StandingStill");
			return 5.0f * DeltaTime;
		}


		//Dashing safe
		else if(SoundType == EMoleStealthDetectionSoundVolume::None && bIsDashing && MoveComp.IsGrounded())
		{
			//Print("Dashing Safe");
			return 37 * DeltaTime;
		}
		//Dashing
		else if(SoundType != EMoleStealthDetectionSoundVolume::None && bIsDashing && MoveComp.IsGrounded())
		{
			//Print("Dashing");
			return 8.f * DeltaTime;
		}


		//Sprinting safe
		else if(SoundType == EMoleStealthDetectionSoundVolume::None && bIsSprinting)
		{
			//Print("Sprinting Safe");
			return 18.f * DeltaTime;
		}
		//Sprinting
		else if(SoundType != EMoleStealthDetectionSoundVolume::None && bIsSprinting)
		{
			//Print("Sprinting");
			return 6.f * DeltaTime;
		}

		// Walking safe
		else if(SoundType == EMoleStealthDetectionSoundVolume::None && MoveComp.IsGrounded())
		{
			//Print("Walking Safe");
			return 0.f;
		}
		// Walking
		else if(SoundType != EMoleStealthDetectionSoundVolume::None && MoveComp.IsGrounded())
		{
			//Print("Walking");
			return 5.0f * DeltaTime;
		}


		// Jumping
		else if(!MoveComp.IsGrounded())
		{
			//Print("Jumping");
			return 0;
		}

		// StandingStill
		else if(MoveComp.Velocity.SizeSquared() > 1)
			return 1.0f * DeltaTime;

		// Default
		else
		{
			//Print("Default");
			return 0.f;
		}
			
	}

	float GetWaterImpactVolumeIncreaseAmount(EMoleStealthDetectionSoundVolume SoundType)
	{
		float Value = 10.f;
		switch(SoundType)
		{
			case EMoleStealthDetectionSoundVolume::Null:
				Value = 0.0f;
				break;


			case EMoleStealthDetectionSoundVolume::Low:
				Value = 0.5f;
				break;

			case EMoleStealthDetectionSoundVolume::Normal:
				Value = 1.0f;
				break;

			case EMoleStealthDetectionSoundVolume::High:
				Value = 10.0f;
				break;

			case EMoleStealthDetectionSoundVolume::InstantDeath:
				Value = 15.0f;
				break;
		}

		return Value;
	}

	float GetVineImpactVolumeIncreaseAmount(bool bFromBlockingHit)
	{
		if(bFromBlockingHit)
			return 20.f;
		else
			return 0.f;
	}
}
