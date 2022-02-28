import Vino.Camera.Capabilities.CameraTags;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;

struct FCannonInputData
{
	bool bPreviousFireInput = false;
	float CannonCoolDownTimer = 0;
}

FVector GetPlayerWheelBoatInput(AHazePlayerCharacter Player)
{
    auto WheelBoatComp = UOnWheelBoatComponent::Get(Player);
    if(WheelBoatComp == nullptr)
        return 0;
    
    return WheelBoatComp.PlayerSteeringInput;
}

class UWheelBoatPlayerInputCapability : UHazeCapability
{
    default CapabilityTags.Add(n"WheelBoat");
	default CapabilityTags.Add(n"WheelBoatInput");
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::StickInput);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(AttributeVectorNames::MovementDirection);
    default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default TickGroup = ECapabilityTickGroups::Input;

	AHazePlayerCharacter Player;
	UOnWheelBoatComponent BoatComp;

	float SendInputTimer = 0;
	const float SendInputDuration = 0.1f;

	const float CannonCoolDownDuration = 0.5f;

	FCannonInputData InputData;
#if TEST
	FCannonInputData OtherInputData;
#endif

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams& Params)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BoatComp = UOnWheelBoatComponent::Get(Owner);
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (BoatComp.WheelBoat == nullptr)
            return EHazeNetworkActivation::DontActivate;

		if (!BoatComp.WheelBoat.BothPlayersAreReady())
			return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BoatComp.WheelBoat == nullptr)
            return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(BoatComp.WheelBoat != nullptr)
		{
			// Clear movement input
		#if TEST
			if(IsActioning(n"WheelBoatSingleInputUsed"))
			{
				BoatComp.WheelBoat.SetBothPlayerDirection(Player, FVector::ZeroVector);
			}
			else
		#endif
			{
				BoatComp.WheelBoat.SetPlayerDirectionInput(Player, FVector::ZeroVector);
			}

			// Clear shoot input
			#if TEST
				if(IsActioning(n"WheelBoatSingleInputUsed"))
				{
					ClearInputData(OtherInputData, Player.GetOtherPlayer());
				}
			#endif
				ClearInputData(InputData, Player);
		}
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		SendInputTimer += DeltaTime;

		if(SendInputTimer >= SendInputDuration)
		{
			// We send over the input to both sides to try to steer the boat locally on both sides
		#if TEST
			if(IsActioning(n"WheelBoatSingleInputUsed"))
			{
				BoatComp.WheelBoat.SetBothPlayerDirection(Player, GetAttributeVector(AttributeVectorNames::LeftStickRaw));
			}
			else
		#endif
			{
				BoatComp.WheelBoat.SetPlayerDirectionInput(Player, GetAttributeVector(AttributeVectorNames::LeftStickRaw));
				//TutorialMovementCheck();
			}
				
			SendInputTimer = 0.0f;
		}
		
	#if TEST
		if(IsActioning(n"WheelBoatSingleInputUsed"))
		{
			UpdateInputData(OtherInputData, Player.GetOtherPlayer(), ActionNames::WeaponAim);
		}
	#endif
		UpdateInputData(InputData, Player, ActionNames::WeaponFire);

	}
	

	void UpdateInputData(FCannonInputData& Input, AHazePlayerCharacter ForPlayer, FName ActionName)
	{
		const bool bFireInput = Time::GetGameTimeSeconds() >= Input.CannonCoolDownTimer && IsActioning(ActionName);
		if(Input.bPreviousFireInput != bFireInput)
		{
			if(!bFireInput)
			{
				const float CooldownAmount = FMath::Lerp(CannonCoolDownDuration * 2.f, CannonCoolDownDuration, BoatComp.ChargeRange);
				Input.CannonCoolDownTimer = Time::GetGameTimeSeconds() + CooldownAmount;
			}

			BoatComp.WheelBoat.SetFireInput(ForPlayer, bFireInput);
			Input.bPreviousFireInput = bFireInput;
		}
	}

	void ClearInputData(FCannonInputData& Input, AHazePlayerCharacter ForPlayer)
	{
		if(Input.bPreviousFireInput)
		{
			BoatComp.WheelBoat.SetFireInput(ForPlayer, false);
			Input.bPreviousFireInput = false;
		}
	}
	
		// else if (BoatComp.WheelBoat.bTutorialMovementActive)
		// {
		// 	if (!BoatComp.WheelBoat.bTutorialShootInputComplete[0] || !BoatComp.WheelBoat.bTutorialShootInputComplete[1])
		// 	{
		// 		if (Player == Game::May)
		// 			BoatComp.WheelBoat.bTutorialShootInputComplete[0] = true;
		// 		else
		// 			BoatComp.WheelBoat.bTutorialShootInputComplete[1] = true;
				
		// 		if (BoatComp.WheelBoat.bTutorialShootInputComplete[0] && BoatComp.WheelBoat.bTutorialShootInputComplete[1])
		// 			BoatComp.WheelBoat.bTutorialShootActive = false;
		// 	}					
		// }

};