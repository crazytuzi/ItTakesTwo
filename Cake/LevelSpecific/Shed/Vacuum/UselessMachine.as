import Vino.Interactions.InteractionComponent;
import Vino.Interactions.AnimNotify_Interaction;
import Cake.LevelSpecific.Shed.VOBanks.VacuumVOBank;

UCLASS(Abstract)
class AUselessMachine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent LidMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeverRoot;

	UPROPERTY(DefaultComponent, Attach = LeverRoot)
	UStaticMeshComponent LeverMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ArmRoot;

	UPROPERTY(DefaultComponent, Attach = ArmRoot)
	UStaticMeshComponent ArmMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UInteractionComponent InteractionComp;

	UPROPERTY(EditDefaultsOnly)
	UVacuumVOBank VOBank;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent UselessMachineActivatedAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayAnimation;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyAnimation;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveArmTimeLike;

	bool bLeverFlippedByPlayer = false;
	bool bLeverFullyFlipped = false;
	bool bLeverFullyReset = true;
	bool bLeverFlippedByArm = false;
	bool bArmMovingForwards = false;

	FHazeConstrainedPhysicsValue LeverPhysValue;
	default LeverPhysValue.LowerBound = -30.f;
	default LeverPhysValue.UpperBound = 30.f;
	default LeverPhysValue.LowerBounciness = 0.2f;
	default LeverPhysValue.UpperBounciness = 0.2f;
	default LeverPhysValue.Friction = 2.1f;

	FHazeAnimNotifyDelegate AnimNotifyDelegate;

	TPerPlayer<int> TimesInteracted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"InteractionActivated");

		MoveArmTimeLike.SetPlayRate(1.5f);
		MoveArmTimeLike.BindUpdate(this, n"UpdateMoveArm");
		MoveArmTimeLike.BindFinished(this, n"FinishMoveArm");
	}

	UFUNCTION()
    void InteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		InteractionComp.Disable(n"Flipped");

		AnimNotifyDelegate.BindUFunction(this, n"LeverFlipped");
        Player.BindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);
		
		UAnimSequence Animation = Player.IsMay() ? MayAnimation : CodyAnimation;
		Player.PlayEventAnimation(Animation = Animation);
    }

	UFUNCTION()
	void LeverFlipped(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMeshComp, UAnimNotify AnimNotify)
	{
		Actor.UnbindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), AnimNotifyDelegate);
		
		bLeverFlippedByPlayer = true;
		LeverPhysValue.AddImpulse(500.f);

		if(UselessMachineActivatedAudioEvent != nullptr)
			UHazeAkComponent::HazePostEventFireForget(UselessMachineActivatedAudioEvent, GetActorTransform());

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		if (Player != nullptr)
		{
			TimesInteracted[Player]++;
			if (TimesInteracted[Player] >= 3)
			{
				if (Player.IsMay())
					PlayFoghornVOBankEvent(VOBank, n"FoghornDBShedVacuumUselessMachineMay");
				else
					PlayFoghornVOBankEvent(VOBank, n"FoghornDBShedVacuumUselessMachineCody");
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMoveArm(float CurValue)
	{
		float CurArmRot = FMath::Lerp(90.f, 0.f, CurValue);
		ArmRoot.SetRelativeRotation(FRotator(CurArmRot, 0.f, 0.f));

		float CurLidRot = FMath::Lerp(0.f, 40.f, CurValue);
		LidMesh.SetRelativeRotation(FRotator(CurLidRot, 0.f, 0.f));

		if (bLeverFlippedByArm)
			return;

		if (bArmMovingForwards && CurValue >= 0.95f)
		{
			bLeverFlippedByArm = true;
			bLeverFlippedByPlayer = false;
			LeverPhysValue.AddImpulse(-500.f);
		}
		else if (!bArmMovingForwards && CurValue >= 0.95f)
		{
			bLeverFlippedByArm = true;
			bLeverFlippedByPlayer = false;
			LeverPhysValue.AddImpulse(-500.f);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMoveArm()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float SpringValue = -30.f;
		if (bLeverFlippedByPlayer)
			SpringValue = 30.f;

		LeverPhysValue.SpringTowards(SpringValue, 200.f);
		LeverPhysValue.Update(DeltaTime);

		LeverRoot.SetRelativeRotation(FRotator(LeverPhysValue.Value, 0.f, 0.f));

		if (LeverPhysValue.HasHitUpperBound() && bLeverFlippedByPlayer && !bLeverFullyFlipped)
		{
			bLeverFullyReset = false;
			bLeverFullyFlipped = true;
			if (!bArmMovingForwards)
			{
				bArmMovingForwards = true;
				bLeverFlippedByArm = false;
				MoveArmTimeLike.Play();
			}
			else
			{
				bArmMovingForwards = false;
				bLeverFlippedByArm = false;
				MoveArmTimeLike.Reverse();
			}
		}

		if (LeverPhysValue.HasHitLowerBound() && bLeverFlippedByArm && !bLeverFullyReset)
		{
			InteractionComp.Enable(n"Flipped");
			bLeverFullyReset = true;
			bLeverFullyFlipped = false;
		}
	}
}