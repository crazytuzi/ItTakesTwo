import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightComponent;
import Vino.Interactions.AnimNotify_Interaction;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightOutsideManager;
import Vino.Triggers.VOBarkPlayerLookAtTrigger;

class ASnowballPickupInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SnowEffectLocation;

	UPROPERTY(Category = "Setup")
	AVOBarkPlayerLookAtTrigger PlayerLookAtTrigger;

	UPROPERTY(Category = "VOBank")
	UFoghornVOBankDataAssetBase VOLevelBank;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UNiagaraSystem SnowEffect;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	FHazeTimeLike SnowMaterialTimeLike;

	UMaterialInstanceDynamic DynamicSnowMaterial;

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet PlayerCapabilitySheetDefault;

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet PlayerCapabilitySheetActive;

	TArray<ASnowballFightOutsideManager> OutsideManagerArray;

	ASnowballFightOutsideManager OutsideManager;

	UPROPERTY()
	float CullDistanceMultiplier = 0.5f;

	UPROPERTY()
	bool bStartDisabled;

	USnowballFightComponent MayComp;
	USnowballFightComponent CodyComp;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		Mesh.SetCullDistance(Editor::GetDefaultCullingDistance(Mesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"OnInteracted");

		DynamicSnowMaterial = Mesh.CreateDynamicMaterialInstance(0);

		SnowMaterialTimeLike.BindUpdate(this, n"OnMaterialTimeLikeUpdate");

		if (bStartDisabled)
			DisableActor(this);
	}

	UFUNCTION()
	void SetActorEnabled()
	{
		if (IsActorDisabled())
			EnableActor(this);
	}

	UFUNCTION()
	void OnInteracted(UInteractionComponent Component, AHazePlayerCharacter InteractingPlayer)
	{
		// We need to add the default capability sheet to both players _if_ they don't already exist
		for (auto Player : Game::Players)
		{
			auto SnowballComp = USnowballFightComponent::Get(Player);

			// No component means the default sheet is not present already
			if (SnowballComp == nullptr)
			{
				Player.AddCapabilitySheet(PlayerCapabilitySheetDefault);
				SnowballComp = USnowballFightComponent::Get(Player);

				// Add active sheet to the interacting player, must happen after Default
				if (Player == InteractingPlayer)
				{
					Player.AddCapabilitySheet(PlayerCapabilitySheetActive);
					SnowballComp.bHasActiveSheet = true;
				}
			}
			else if (Player == InteractingPlayer && !SnowballComp.bHasActiveSheet)
			{
				// We already have the snowball comp, but not the active sheet
				// this happens when the other player has interacted with the snowballs, but not us
				Player.AddCapabilitySheet(PlayerCapabilitySheetActive);
				SnowballComp.bHasActiveSheet = true;
			}
		}

		InteractingPlayer.SetCapabilityActionState(n"ReloadingSnowball", EHazeActionState::Active);
		InteractingPlayer.SetCapabilityActionState(n"SnowballTutorial", EHazeActionState::Active);
		InteractingPlayer.SetCapabilityAttributeObject(n"PickupActor", this);

		FName EventName = (InteractingPlayer.IsMay() ? 
			n"FoghornDBSnowGlobeTownSnowballsPickUpMay" :
			n"FoghornDBSnowGlobeTownSnowballsPickUpCody");

		PlayFoghornVOBankEvent(VOLevelBank, EventName);

		Niagara::SpawnSystemAtLocation(SnowEffect, SnowEffectLocation.WorldLocation);

		if(SnowMaterialTimeLike.IsReversed())
			SnowMaterialTimeLike.Play();
		else
			SnowMaterialTimeLike.Reverse();
	}

	UFUNCTION()
	void OnMaterialTimeLikeUpdate(float Value)
	{
		DynamicSnowMaterial.SetScalarParameterValue(n"BlendValue", Value);
	}
}