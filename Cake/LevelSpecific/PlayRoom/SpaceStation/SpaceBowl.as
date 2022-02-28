import Vino.Interactions.InteractionComponent;
import Vino.Pickups.PickupActor;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Vino.Pickups.PlayerPickupComponent;

event void FOnSpaceBowlDestroyed();

UCLASS(Abstract)
class ASpaceBowl : APickupActor
{
    UPROPERTY(DefaultComponent, Attach = Base)
    UInteractionComponent InteractionPoint;
	default InteractionPoint.ActionShape.Type = EHazeShapeType::Sphere;
	default InteractionPoint.ActionShape.SphereRadius = 350.f;
	default InteractionPoint.FocusShape.Type = EHazeShapeType::Sphere;
	default InteractionPoint.FocusShape.SphereRadius = 1000.f;
	default InteractionPoint.Visuals.VisualOffset.Location = FVector(0.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent)
	UCharacterChangeSizeCallbackComponent ChangeSizeCallbackComp;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSettingsDataAsset CamSettings;

	UPROPERTY()
	FOnSpaceBowlDestroyed OnSpaceBowlDestroyed;

	AHazePlayerCharacter PlayerInSpaceBowl;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> EnterCapability;
    
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		APickupActor::BeginPlay();
		InteractionPoint.OnActivated.AddUFunction(this, n"OnInteractionActivated");

		Capability::AddPlayerCapabilityRequest(EnterCapability.Get(), EHazeSelectPlayer::Cody);
    }

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(EnterCapability.Get(), EHazeSelectPlayer::Cody);
	}

    UFUNCTION()
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
        InteractionPoint.Disable(n"Entered");
		Player.SetCapabilityAttributeObject(n"SpaceBowl", this);
        Player.SetCapabilityActionState(n"EnterSpaceBowl", EHazeActionState::Active);
		FHazeCameraBlendSettings CamBlend;
		CamBlend.BlendTime = 1.f;
		Player.ApplyCameraSettings(CamSettings, CamBlend, this, EHazeCameraPriority::Maximum);
		PlayerInSpaceBowl = Player;
    }

	void SpaceBowlLeft(AHazePlayerCharacter Player)
	{
		InteractionPoint.Enable(n"Entered");
		Player.ClearCameraSettingsByInstigator(this);
		PlayerInSpaceBowl = nullptr;
	}

	UFUNCTION()
	void RespawnSpaceBowl()
	{	
		if (IsPickedUp())
		{
			AHazePlayerCharacter PlayerHoldingBowl = HoldingPlayer;
			UPlayerPickupComponent::Get(PlayerHoldingBowl).ForceDrop(false);
		}

		Mesh.SetSimulatePhysics(false);
		OnSpaceBowlDestroyed.Broadcast();
		EjectPlayerFromSpaceBowl();
	}

	UFUNCTION()
	void EjectPlayerFromSpaceBowl()
	{
		if (PlayerInSpaceBowl != nullptr)
		{
			PlayerInSpaceBowl.BlockCapabilities(n"Gravity", this);
			PlayerInSpaceBowl.UnblockCapabilities(n"Gravity", this);
		}
	}

	UFUNCTION()
	void AllowLeaving()
	{
		
	}

	UFUNCTION()
	void BlockLeaving()
	{

	}

}