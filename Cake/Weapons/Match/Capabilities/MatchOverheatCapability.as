
import Cake.Weapons.Match.MatchWeaponActor;
import Cake.Weapons.Match.MatchProjectileActor;
import Cake.Weapons.Match.MatchWielderComponent;
import Cake.Weapons.Match.MatchWeaponStatics;
import Cake.Weapons.Match.MatchWeaponSocketDefinition;

import Peanuts.Aiming.AutoAimStatics;
import Vino.Movement.Components.MovementComponent;

UCLASS()
class UMatchOverheatCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"MatchWeaponOverheat");
	default CapabilityTags.Add(n"MatchWeapon");
	default CapabilityTags.Add(n"Weapon");

	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroupOrder = 101;

	//////////////////////////////////////////////////////////////////////////
	// Settings

	float OverheatFromShot = 1.f;
	float OverheatThreshold = 1.0f;

	// Settings
	//////////////////////////////////////////////////////////////////////////
	// Transients 

	AMatchWeaponActor MatchWeapon = nullptr;
	UMatchWielderComponent WielderComp = nullptr;
	AHazePlayerCharacter Player = nullptr;

	int PrevChargesFloored = 0;

	// Transient 
	//////////////////////////////////////////////////////////////////////////
	// Functions

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WielderComp = UMatchWielderComponent::GetOrCreate(Owner);
		MatchWeapon = WielderComp.GetMatchWeapon();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// return EHazeNetworkActivation::ActivateUsingCrumb;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams) 
	{
		MatchWeapon.OnMatchShoot.AddUFunction(this, n"HandleMatchShoot");
		PrevChargesFloored = FMath::FloorToInt(WielderComp.Charges);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MatchWeapon.OnMatchShoot.Unbind(this, n"HandleMatchShoot");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AdvectTemp(WielderComp.Charges, DeltaTime);

		if(WielderComp.bOverheating && WielderComp.Charges > 1.f)
			WielderComp.bOverheating = false;

		const int ChargesFloored = FMath::FloorToInt(WielderComp.Charges);

		// Handle ammo uppdated either gained or lost
		if (ChargesFloored != PrevChargesFloored)
		{
			HandleMatchChargeUpdated(ChargesFloored);
		}

		// handle ammo increased _only_ 
		if(ChargesFloored > PrevChargesFloored)
		{
			HandleMatchChargeGained(ChargesFloored);
		}

		UpdateForceFeedback();

		PrevChargesFloored = ChargesFloored;
	}

	void UpdateForceFeedback()
	{
		// full ammo check
		if (WielderComp.Charges == 3.f)
			return;

		// forcefeedback when you gain first ammo after full depletion
		if (FMath::IsWithin(WielderComp.Charges, 1.0f, 1.1f))
		{
			const float FF_ChargeGained = 0.4f;
			Player.SetFrameForceFeedback(FF_ChargeGained, FF_ChargeGained);
		}

		// // forcefeedback when you gain ammo
		// float FF_ChargeGained = 0.f;
		// if (FMath::IsWithin(WielderComp.Charges, 1.f, 1.1f))
		// 	FF_ChargeGained = 0.4f;
		// else if (FMath::IsWithin(WielderComp.Charges, 1.95f, 2.f))
		// 	FF_ChargeGained = 0.6f;
		// else if (FMath::IsWithin(WielderComp.Charges, 2.95f, 3.f))
		// 	FF_ChargeGained = 0.4f;
		// Player.SetFrameForceFeedback(FF_ChargeGained, FF_ChargeGained);

		// rumble when ammo if fully depleted up until you get the first ammo back
		if(WielderComp.bOverheating)
		{
			float FF_Strong = 1.f - (WielderComp.Charges / 3.f);
			FF_Strong = FMath::Pow(FF_Strong, 5.5f);
			FF_Strong *= 0.1f;
			const float FF_Small = FF_Strong;
			Player.SetFrameForceFeedback(FF_Strong, FF_Small);
		}

	}

	void AdvectTemp(float& TempToAdvect, const float Dt)
	{
		const float DesiredValue = 3.f;
		const float LinearSpeed = 0.6f;
		TempToAdvect += (Dt * LinearSpeed);
		if(TempToAdvect >= DesiredValue)
			TempToAdvect = DesiredValue;
	}

	UFUNCTION()
	void HandleMatchShoot()
	{
		WielderComp.Charges -= OverheatFromShot;
		if(WielderComp.Charges < OverheatThreshold)
		{
			WielderComp.bOverheating = true;
		}
	}

	void HandleMatchChargeUpdated(const float InChargesFloored)
	{
		WielderComp.OnMatchChargeUpdated.Broadcast(InChargesFloored);
		Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Weapons_Guns_Rifle_Match_ProjectileCount", InChargesFloored, 200.f);
	}

	void HandleMatchChargeGained(const float InChargesFloored)
	{
		if(WielderComp.Charges >= 3.f)
		{
			Player.PlayerHazeAkComp.HazePostEvent(MatchWeapon.FullyReloadedEvent);
//			Print("Fully Reload Event", 5.f, FLinearColor::Black);
		}
		else
		{
			Player.PlayerHazeAkComp.HazePostEvent(MatchWeapon.ReloadEvent);
//			Print("Reload Event", 5.f, FLinearColor::Purple);
		}
	}

    /* Used by the Capability debug menu to show Custom debug info */
	UFUNCTION(BlueprintOverride)
	FString GetDebugString() const
	{
		FVector TempVec = FVector(400.f, 10.f, 0.f);

		FString Str = "Overheat data";

		Str += "\n";
		Str += "\n";

		Str += "OverheatAccumulated: <Yellow>";
		Str += WielderComp.OverheatAccumulated;
		Str += "</>";

		Str += "\n";
		Str += "\n";

		Str += "Charges: <Yellow>";
		Str += WielderComp.Charges;
		Str += "</>";

		Str += "\n";

		Str += "\n";
		Str += "\n";

        return Str;
	}

}