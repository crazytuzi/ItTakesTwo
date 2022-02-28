import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCraneRidingComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.HeadButtingDino;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Camera.Components.CameraSplineFollowerComponent;
import Vino.Camera.Components.CameraFollowViewComponent;

class UDinoCraneEatOtherPlayerCapability : UHazeCapability
{
	const float Cooldown = 8.f;

    default CapabilityTags.Add(CapabilityTags::GameplayAction);

	ADinoCrane DinoCrane;
	bool bWasEatingOtherPlayer = false;
	AHeadButtingDino EatingSlammer;
	FTransform PreviousSlammerTransform;

	UCameraFollowViewComponent CamParent;
	UHazeCameraComponent CamComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams& Params)
	{
		DinoCrane = Cast<ADinoCrane>(Owner);

		CamParent = UCameraFollowViewComponent::GetOrCreate(Owner, n"EatOtherPlayerCamParent");
		CamComp = UHazeCameraComponent::GetOrCreate(Owner, n"EatOtherPlayerCamera");
		CamComp.AttachTo(CamParent);
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (DinoCrane.bIsEatingOtherPlayer)
			return EHazeNetworkActivation::ActivateLocal;
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!DinoCrane.bIsEatingOtherPlayer)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	AHeadButtingDino GetDinoSlammer()
	{
		// Probably should be a better way to do this but it doesn't really matter right now
		TArray<AHeadButtingDino> Dinos;
		GetAllActorsOfClass(Dinos);
		return Dinos[0];
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams& Params)
    {
		bWasEatingOtherPlayer = false;
		EatingSlammer = GetDinoSlammer();

		auto EatenPlayer = DinoCrane.RidingPlayer.OtherPlayer;
		DinoCrane.RidingPlayer.BlockCapabilities(n"GameplayAction", this);
		DinoCrane.BlockCapabilities(n"DinoCraneMovement", this);

		DinoCrane.SetPositionOfDinoHead(EatenPlayer.ActorLocation, DinoCrane.GetActorForwardVector());

		// If the other player is on the dino slammer, we need to play some different animations
		const bool bOtherPlayerOnSlammer = (EatingSlammer.RidingPlayer == EatenPlayer);
		DinoCrane.SetAnimBoolParam(n"DinoCraneEatingSlammerDino", bOtherPlayerOnSlammer);
		if (bOtherPlayerOnSlammer)
		{
			PreviousSlammerTransform = EatingSlammer.ActorTransform;
			System::SetTimer(this, n"StartEatingSlammerAnim", 0.25f, false);
		}
		else
		{
			EatingSlammer = nullptr;
			System::SetTimer(this, n"StartEatingAnim", 0.25f, false);
		}
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams& Params)
    {
		DinoCrane.SetAnimBoolParam(n"DinoCraneEatingOtherPlayer", false);
		DinoCrane.SetAnimBoolParam(n"DinoCraneEatingSlammerDino", false);

		ensure(DinoCrane.RidingPlayer != nullptr);
		auto EatenPlayer = DinoCrane.RidingPlayer.OtherPlayer;

		EatenPlayer.DetachRootComponentFromParent();
		DinoCrane.RidingPlayer.UnblockCapabilities(n"GameplayAction", this);
		DinoCrane.UnblockCapabilities(n"DinoCraneMovement", this);

		DinoCrane.EatOtherCooldownUntil = Time::GameTimeSeconds + Cooldown;

		for (auto Player : Game::Players)
			Online::UnlockAchievement(Player, n"Extinction");

		// Kill the player we ate
		if (EatingSlammer != nullptr)
		{
			EatingSlammer.DetachRootComponentFromParent();
			EatingSlammer.SetMovementEnabled(true);
			EatingSlammer.SetActorEnableCollision(true);

			EatingSlammer.JumpOnDino(EatenPlayer, true);
			EatingSlammer.TriggerDeathEffets(PreviousSlammerTransform);
		}
		else
		{
			EatenPlayer.KillPlayer();
		}
    }

	UFUNCTION()
	void StartEatingAnim()
	{
		auto EatenPlayer = DinoCrane.RidingPlayer.OtherPlayer;

		EatenPlayer.PlayEventAnimation(
			Animation = EatenPlayer.IsCody() ? DinoCrane.EatOtherPlayerAnimation_Cody : DinoCrane.EatOtherPlayerAnimation_May,
			OnBlendingOut = FHazeAnimationDelegate(this, n"StopEatingOtherPlayer")
		);

		EatenPlayer.AttachToComponent(DinoCrane.Mesh, n"JawLower");
	}

	UFUNCTION()
	void StartEatingSlammerAnim()
	{
		auto EatenPlayer = DinoCrane.RidingPlayer.OtherPlayer;

		EatingSlammer.JumpOff();

		EatenPlayer.PlayEventAnimation(
			Animation = EatenPlayer.IsCody() ? DinoCrane.EatOtherPlayerAndSlammerAnimation_Cody : DinoCrane.EatOtherPlayerAndSlammerAnimation_May,
			OnBlendingOut = FHazeAnimationDelegate(this, n"StopEatingOtherPlayer"),
			BlendTime = 0.f
		);

		EatingSlammer.SetActorEnableCollision(false);
		EatingSlammer.PlaySlotAnimation(
			Animation = DinoCrane.EatOtherPlayerAndSlammerAnimation_DinoSlammer,
			BlendTime = 0.f
		);

		EatenPlayer.AttachToComponent(DinoCrane.Mesh, n"JawLower");
		EatingSlammer.AttachToComponent(DinoCrane.Mesh, n"JawLower");
		EatingSlammer.SetMovementEnabled(false);

		EatenPlayer.SetAnimBoolParam(n"SkipDinoEnter", true);
		EatingSlammer.SetAnimBoolParam(n"SkipDinoEnter", true);

		EatenPlayer.ActivateCamera(CamComp, FHazeCameraBlendSettings(0.5f), this);

		DinoCrane.SetAnimBoolParam(n"DinoCraneEatingOtherPlayer", false);
		DinoCrane.SetAnimBoolParam(n"DinoCraneEatingSlammerDino", false);
	}

	UFUNCTION()
	void StopEatingOtherPlayer()
	{
		auto EatenPlayer = DinoCrane.RidingPlayer.OtherPlayer;
		EatingSlammer.StopAllSlotAnimations(0);
		EatenPlayer.StopAllSlotAnimations(0);
		EatenPlayer.SetAnimBoolParam(n"IsRespawning", true);
		EatingSlammer.SetAnimBoolParam(n"IsRespawning", true);
		DinoCrane.StopEatingOtherPlayer();

		EatenPlayer.SetAnimBoolParam(n"SkipDinoEnter", true);
		EatingSlammer.SetAnimBoolParam(n"SkipDinoEnter", true);
		EatenPlayer.DeactivateCameraByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Make sure the animation is updated
		if (bWasEatingOtherPlayer)
		{
			DinoCrane.SetAnimBoolParam(n"DinoCraneEatingOtherPlayer", false);
		}
		else
		{
			DinoCrane.SetAnimBoolParam(n"DinoCraneEatingOtherPlayer", true);
			bWasEatingOtherPlayer = true;
		}
	}
};