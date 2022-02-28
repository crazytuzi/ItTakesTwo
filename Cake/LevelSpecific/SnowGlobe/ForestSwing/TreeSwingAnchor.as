import Vino.Movement.Swinging.SwingPoint;
import Vino.Movement.Swinging.SwingComponent;
import Cake.LevelSpecific.SnowGlobe.ForestSwing.TreeNiagaraActor;

class ATreeSwingAnchor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(Category = "Setup")
	ATreeNiagaraActor TreeNiagara;

	UPROPERTY(Category = "Setup")
	ASwingPoint SwingPointActor;

	UPROPERTY(Category = "Setup")
	float RotationMultiplier = 8.f;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 3000.f;

	USwingPointComponent SwingPointComp;

	TPerPlayer<AHazePlayerCharacter> Players;

	float TargetPitchToAdd;

	FVector StartUpVector;
	FRotator StartRot;

	FHazeAcceleratedRotator AccelRot;

	bool bActivateSystem;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (SwingPointActor != nullptr)
		{
			SwingPointComp = USwingPointComponent::Get(SwingPointActor);
			SwingPointComp.OnSwingPointAttached.AddUFunction(this, n"PlayerAttach");
			SwingPointComp.OnSwingPointDetached.AddUFunction(this, n"PlayerDetach");
		}

		StartUpVector = -SwingPointActor.ActorUpVector;
		StartRot = ActorRotation;
		AccelRot.SnapTo(ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		int Divider = 0;
		float PitchAmountPerPlayer = 0.f;

		for (AHazePlayerCharacter Player : Players)
		{
			if (Player == nullptr)
				continue;

			FVector PlayerDir = Player.ActorLocation - SwingPointActor.ActorLocation;
			PlayerDir.Normalize();

			float Dot = StartUpVector.DotProduct(PlayerDir);
			float Multiplier =	Dot  - 0.22f;
			Multiplier = FMath::Clamp(Multiplier, 0.f, 1.f);

			PitchAmountPerPlayer += RotationMultiplier * Multiplier;

			Divider++;
		}

		if (Divider != 0.f)
		{
			TargetPitchToAdd = PitchAmountPerPlayer / Divider;
		}

		FRotator NewRot = StartRot + FRotator(-TargetPitchToAdd, 0.f, 0.f);
		AccelRot.AccelerateTo(NewRot, 0.5f, DeltaTime);

		SetActorRotation(AccelRot.Value);
	}
	
	UFUNCTION()
	void PlayerAttach(AHazePlayerCharacter Player)
	{
		if (Player == Game::May)
			Players[0] = Player;
		else
			Players[1] = Player;

		if (TreeNiagara != nullptr)
			TreeNiagara.ActivateSystem();
	}

	UFUNCTION()
	void PlayerDetach(AHazePlayerCharacter Player)
	{
		if (Player == Game::May)
			Players[0] = nullptr;
		else
			Players[1] = nullptr;
	}
}