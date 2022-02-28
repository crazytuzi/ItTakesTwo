import Vino.Pickups.PickupActor;
import Vino.Movement.Swinging.SwingComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

class APickupableSwingPoint : APickupActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent SwingPointRoot;

	UPROPERTY(DefaultComponent, Attach = SwingPointRoot)
	USceneComponent SwingLeftRoot;

	UPROPERTY(DefaultComponent, Attach = SwingLeftRoot)
	UStaticMeshComponent SwingLeftmesh;

	UPROPERTY(DefaultComponent, Attach = SwingPointRoot)
	USceneComponent SwingRightRoot;

	UPROPERTY(DefaultComponent, Attach = SwingRightRoot)
	UStaticMeshComponent SwingRightMesh;

	UPROPERTY(DefaultComponent, Attach = SwingPointRoot)
	USwingPointComponent SwingPointComp;

	UPROPERTY(DefaultComponent)
	UCharacterChangeSizeCallbackComponent ChangeSizeCallbackComp;

	UPROPERTY(NotEditable)
	float FullyExposedOffset = 70.f;
	UPROPERTY(NotEditable)
	float FullyHiddenOffset = -35.f;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	protected void OnPickedUpDelegate(AHazePlayerCharacter Player, APickupActor PickupActor) override
	{
		Super::OnPickedUpDelegate(Player, PickupActor);
		SetActorTickEnabled(true);
	}

	bool bPlayerDead = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!IsPickedUp())
		{
			SetActorTickEnabled(false);
			return;
		}

		if (HoldingPlayer.IsPlayerDead())
		{
			if (!bPlayerDead)
			{
				bPlayerDead = true;
				SwingPointComp.SetSwingPointEnabled(false);
			}
		}
		else
		{
			if (bPlayerDead)
			{
				bPlayerDead = false;
				SwingPointComp.SetSwingPointEnabled(true);
			}
		}

	}
}