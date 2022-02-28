import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.UI.CastlePlayerHUDWidget;
import Peanuts.Outlines.Outlines;

class UCastlePlayerCapability : UHazeCapability
{
    default CapabilityTags.Add(n"Castle");

    default CapabilityDebugCategory = n"Castle";

	default TickGroupOrder = 1;
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	

    UPROPERTY(NotEditable)
    AHazePlayerCharacter OwningPlayer;
    UPROPERTY(NotEditable)
    UCastleComponent CastleComponent;

    UPROPERTY()
    TSubclassOf<UCastleDamageNumberWidget> DamageNumberWidget;
	UPROPERTY()
	USkeletalMesh CastlePlayerMesh;
	UPROPERTY()
    UHazeLocomotionStateMachineAsset StateMachineAsset;
	
	USkeletalMesh OriginalPlayerMesh;

	UPROPERTY()
	TSubclassOf<UCastlePlayerAbilityBarWidget> WidgetClass;

	UPROPERTY()
	UCastleAbilitySlotData AbilitySlotData;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		CastleComponent = UCastleComponent::Get(Owner);

		CastleComponent.DamageNumberWidget = DamageNumberWidget;

		CastleComponent.GetOrCreateHUD().GetAbilityBarForPlayer(OwningPlayer);		
		UCastleAbilitySlotData SlotData = AbilitySlotData;
		GetAbilityBarWidget().UpdateAbilityData(SlotData);		
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}    

	UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		UCastlePlayerAbilityBarWidget AbilityBar = CastleComponent.GetOrCreateHUD().GetAbilityBarForPlayer(OwningPlayer);
		AbilityBar.UltimateProgress = CastleComponent.UltimatePercentage;
		AbilityBar.bIsUsingUltimate = CastleComponent.bUsingUltimate;

		if (IsPlayerDead(OwningPlayer))
			AbilityBar.SetVisibility(ESlateVisibility::Collapsed);
		else
			AbilityBar.SetVisibility(ESlateVisibility::HitTestInvisible);
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		if (CastlePlayerMesh != nullptr)
		{
			OriginalPlayerMesh = OwningPlayer.Mesh.SkeletalMesh;
			OwningPlayer.SetPlayerMesh(CastlePlayerMesh, true);
		}

		if (StateMachineAsset != nullptr)
			OwningPlayer.AddLocomotionAsset(StateMachineAsset, this);			

			FOutline Outline = OwningPlayer.IsMay() ? FOutlines::May : FOutlines::Cody;
			Outline.Viewport = EOutlineViewport::Both;
			//Outline.DisplayMode = EOutlineDisplayMode::OccludedPortion;
			Outline.BorderOpacity = 1.f;
			Outline.BorderWidth = 10.f;
			Outline.FillOpacity = 0.28f;

			CreateNewMeshOutline(OwningPlayer.Mesh, Outline, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{       
		if (OriginalPlayerMesh != nullptr)
		{
			OwningPlayer.SetPlayerMesh(OriginalPlayerMesh, true);
		}

		if (StateMachineAsset != nullptr)
			OwningPlayer.ClearLocomotionAssetByInstigator(this);
	} 

	UFUNCTION(BlueprintPure)
	UCastlePlayerAbilityBarWidget GetAbilityBarWidget()
	{
		return CastleComponent.GetOrCreateHUD().GetAbilityBarForPlayer(OwningPlayer);
	}
}