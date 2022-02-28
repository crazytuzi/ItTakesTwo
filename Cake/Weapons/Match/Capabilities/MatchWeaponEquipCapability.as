import Cake.Weapons.Match.MatchWielderComponent;
import Peanuts.Outlines.Outlines;

class UMatchWeaponEquipCapability : UHazeCapability 
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Weapon);
	default CapabilityTags.Add(n"MatchWeapon");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 20;

	UMatchWielderComponent WielderComp = nullptr;
	AHazePlayerCharacter Player = nullptr;
	AMatchWeaponActor Weapon = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WielderComp = UMatchWielderComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WielderComp.MatchWeapon == nullptr)
	        return EHazeNetworkActivation::DontActivate;

		if (WielderComp.Settings == nullptr)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WielderComp.MatchWeapon == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AddMeshToPlayerOutline(WielderComp.MatchWeapon.Mesh, Player, this);
		AddMeshToPlayerOutline(WielderComp.QuiverMesh, Player, this);
		for(AMatchProjectileActor Match : WielderComp.Matches)
			AddMeshToPlayerOutline(Match.Mesh, Player, this);

		Player.AddLocomotionAsset(WielderComp.Settings.LocomotionAsset_NotAiming, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveMeshFromPlayerOutline(WielderComp.MatchWeapon.Mesh, this);
		RemoveMeshFromPlayerOutline(WielderComp.QuiverMesh, this);
		for(AMatchProjectileActor Match : WielderComp.Matches)
			RemoveMeshFromPlayerOutline(Match.Mesh, this);

		Player.ClearLocomotionAssetByInstigator(this);
	}

	int BlockCounter = 0;
	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		BlockCounter++;
		if (BlockCounter == 1 && WielderComp.MatchWeapon != nullptr)
		{
			WielderComp.MatchWeapon.DisableActor(this);

			for(AMatchProjectileActor Match : WielderComp.Matches)
				Match.DisableActor(this);

			WielderComp.QuiverMesh.SetHiddenInGame(true, false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{
		BlockCounter--;
		if (BlockCounter == 0 && WielderComp.MatchWeapon != nullptr)
		{
			WielderComp.MatchWeapon.EnableActor(this);

			for(AMatchProjectileActor Match : WielderComp.Matches)
				Match.EnableActor(this);

			WielderComp.QuiverMesh.SetHiddenInGame(false, false);
		}
	}

}