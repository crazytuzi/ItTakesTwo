import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;


struct FParentBlobDelayInput
{
	float RemainingDelay = 0.f;
	FVector2D RawInput;
};

const float PARENTBLOB_DELAY = 0.25f;

class UParentBlobPlayerInputCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Input");
	default CapabilityTags.Add(n"Movement");
	default CapabilityTags.Add(n"MovementInput");
	default CapabilityTags.Add(n"ParentBlob");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default CapabilityDebugCategory = n"ParentBlob";

	TArray<FParentBlobDelayInput> InputDelayLine;

	AHazePlayerCharacter Player;
	AParentBlob ParentBlob;
	UParentBlobPlayerComponent ParentBlobComponent;
		
	int SentInputCounter = 0;
	int ReceivedInputCounter = -1;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ParentBlobComponent = UParentBlobPlayerComponent::Get(Player);
		ParentBlob = ParentBlobComponent.ParentBlob;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSendInput(int InputCounter, FVector2D RawInput)
	{
		if (HasControl())
			return;
		if (InputCounter < ReceivedInputCounter)
			return;
		if (ParentBlob != nullptr)
			ParentBlob.PlayerRawInput[Player] = RawInput;
		ReceivedInputCounter = InputCounter;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			FVector2D InputRawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

			// Immediately update the raw input used for visuals (arm pointing)
			ParentBlob.PlayerRawInput[Player] = InputRawStick;

			// Send the raw input to the other side ASAP so it can be used quickly
			NetSendInput(SentInputCounter++, InputRawStick);
		}

		// Run a delay line for the input we're going to use for movement direction
		if (ParentBlob.HasControl())
		{
			FParentBlobDelayInput Input;
			Input.RemainingDelay = PARENTBLOB_DELAY;
			Input.RawInput = ParentBlob.PlayerRawInput[Player];
			if (!HasControl())
				Input.RemainingDelay -= Network::GetPingRoundtripSeconds();
			InputDelayLine.Add(Input);

			// Take the input from the delay line
			for (int i = 0, Count = InputDelayLine.Num(); i < Count; ++i)
			{
				FParentBlobDelayInput& PrevInput = InputDelayLine[i];
				PrevInput.RemainingDelay -= DeltaTime;

				if (PrevInput.RemainingDelay <= 0)
				{
					ParentBlob.UpdatePlayerMovementDirection(Player, PrevInput.RawInput);
					InputDelayLine.RemoveAt(i);
					--i; --Count;
				}
			}
		}
	}
};