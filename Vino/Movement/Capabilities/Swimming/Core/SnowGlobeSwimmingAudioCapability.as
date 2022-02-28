import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Swimming.Core.SnowGlobeSwimmingCapability;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
import Vino.Audio.Movement.PlayerMovementAudioComponent;

class USnowGlobeSwimmingAudioCapability : UHazeCapability
{
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(n"SwimmingAudio");

	default CapabilityDebugCategory = n"Movement Swimming";
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 180;

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp;
	UPlayerHazeAkComponent HazeAkComp;
	UPlayerMovementAudioComponent AudioMoveComp;

	TPerPlayer<USnowGlobeSwimmingComponent> SwimmingComps;

	float OwnerInWater = 0.f;
	float BothInWater = 0.f;	

	bool LastWasInWater;	
	FString PlayerInWaterRTPCName = "";

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner);
		AudioMoveComp = UPlayerMovementAudioComponent::Get(Owner);

		SwimmingComps[Player] = USnowGlobeSwimmingComponent::Get(Player);
		SwimmingComps[Player.OtherPlayer] = USnowGlobeSwimmingComponent::Get(Player.OtherPlayer);

		CheckAndUpdateOwnerInWater(true);
		CheckAndUpdateBothInWater(true);

		if(Player.IsMay())
			PlayerInWaterRTPCName = "Rtpc_VO_IsInWater_May";
		else
			PlayerInWaterRTPCName = "Rtpc_VO_IsInWater_Cody";
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (SwimmingComps[Player.OtherPlayer] == nullptr)
			SwimmingComps[Player.OtherPlayer] = USnowGlobeSwimmingComponent::Get(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// if (SwimmingComps[Player].bIsInWater)
		// 	return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// if(SwimmingComps[Player].bIsInWater)
			// return EHazeNetworkDeactivation::DontDeactivate;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CheckAndUpdateOwnerInWater();
		CheckAndUpdateBothInWater();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		CheckAndUpdateOwnerInWater();
		CheckAndUpdateBothInWater();
	}

	void CheckAndUpdateOwnerInWater(bool bForce = false)
	{
		if (SwimmingComps[Player.OtherPlayer] == nullptr)
			return;

		float Value = 0.f;
		Value += SwimmingComps[Game::May].bIsUnderwater ? -1.f : 0.f;
		Value += SwimmingComps[Game::Cody].bIsUnderwater ? 1.f : 0.f;

		if (bForce || !FMath::IsNearlyEqual(OwnerInWater, Value))
		{			
			OwnerInWater = Value;

			FString RTPCName = "Rtpc_Player_IsInWater";			
			UHazeAkComponent::HazeSetGlobalRTPCValue(RTPCName, OwnerInWater);
		}

		const bool bIsInWater = SwimmingComps[Player].bForceUnderwater ? true : SwimmingComps[Player].bIsUnderwater;
		if(bIsInWater != LastWasInWater)
		{
			float InWaterValue = bIsInWater ? 1.f : 0.f;
			UHazeAkComponent::HazeSetGlobalRTPCValue(PlayerInWaterRTPCName, InWaterValue);
			LastWasInWater = bIsInWater;
		}		
	}

	void CheckAndUpdateBothInWater(bool bForce = false)
	{
		if (SwimmingComps[Player.OtherPlayer] == nullptr)
			return;			

		float Value = 0.f;
		Value += SwimmingComps[Player].bIsUnderwater ? 0.5f : 0.f;
		Value += SwimmingComps[Player.OtherPlayer].bIsUnderwater ? 0.5f : 0.f;

		if (bForce || !FMath::IsNearlyEqual(BothInWater, Value))
		{
			BothInWater = Value;

			FString RTPCName = "Rtpc_Player_IsInWater_BothPlayers";			
			UHazeAkComponent::HazeSetGlobalRTPCValue(RTPCName, BothInWater);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		FString RTPCName = "Rtpc_Player_IsInWater_BothPlayers";
		UHazeAkComponent::HazeSetGlobalRTPCValue(RTPCName, 0.f);

		FString RTPCName2 = "Rtpc_Player_IsInWater";
		UHazeAkComponent::HazeSetGlobalRTPCValue(RTPCName, 0.f);

		UHazeAkComponent::HazeSetGlobalRTPCValue(PlayerInWaterRTPCName, 0.f);
	}
}