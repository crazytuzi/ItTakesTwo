import Peanuts.SpeedEffect.SpeedEffectComponent;
import Effects.PostProcess.PostProcessing;
import Vino.Camera.Components.CameraUserComponent;

class USpeedEffectCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ScreenEffect");
	default CapabilityTags.Add(n"SpeedEffect");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 170;

	AHazePlayerCharacter Player;
	UCameraUserComponent CameraUserComp;
	USpeedEffectComponent SpeedEffectComp;

	UPostProcessingComponent PostProcessComp;
	UPROPERTY()
	UNiagaraComponent SpeedEffectNiagaraComp;

	FString SpeedEffectDebugString;

	/* SPEED EFFECT VALUE */
	const float SpeedEffectValueInterpSpeedUpwards = 2.f;
	const float SpeedEffectValueInterpSpeedDownwards = 1.f;
	const float MaximumValue = 5.f;

	/* NIAGARA EFFECT */
	FRotator NiagaraRotation;
	const float NiagaraEffectInterpSpeed = 260.f;

	/* SCREEN EFFECT */
	const float SpeedShimmerScale = 0.8f;


	// Speed effect = FoV & DoF (maybe some shimmer, but hopefully DoF can fix)

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CameraUserComp = UCameraUserComponent::Get(Owner);
		SpeedEffectComp = USpeedEffectComponent::GetOrCreate(Owner);
		PostProcessComp = UPostProcessingComponent::GetOrCreate(Owner);

		NiagaraRotation = TargetNiagaraEffectRotation;
		SpeedEffectNiagaraComp = Niagara::SpawnSystemAttached(SpeedEffectComp.SpeedEffect, Player.RootComponent, NAME_None, FVector::ZeroVector, NiagaraRotation, EAttachLocation::SnapToTarget, false, false);
		SpeedEffectNiagaraComp.SetRenderedForPlayer(Player.OtherPlayer, false);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (SpeedEffectNiagaraComp != nullptr)
		{
			FRotator CurrentRotation = SpeedEffectNiagaraComp.WorldRotation;
			NiagaraRotation = FMath::RInterpConstantTo(CurrentRotation, TargetNiagaraEffectRotation, DeltaTime, NiagaraEffectInterpSpeed);
		}

		// Update the components value
		UpdateEffectValue(DeltaTime);

#if EDITOR
		if (IsDebugActive())
		{
			SpeedEffectDebugString = "<Yellow>Value:</> " + SpeedEffectComp.Value + "\n\n";
			SpeedEffectDebugString += "<Red>Speed Effect Requests: </>\n";
			for (FSpeedEffectRequest Request : SpeedEffectComp.ValueRequests)
			{
				SpeedEffectDebugString += "" + Request.Instigator.Name + "\n";
				SpeedEffectDebugString += "        <Blue>Value</>: " + Request.Value + "        <Green>Snap:</> " + Request.bSnap + "\n" ;
			}
		}
#endif
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SceneView::IsFullScreen())
        	return EHazeNetworkActivation::DontActivate;

		if (IsAnySpeedEffectMoreThanZero())
     	   return EHazeNetworkActivation::ActivateLocal;

		if (SpeedEffectComp.Value <= 0.f)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	bool IsAnySpeedEffectMoreThanZero() const
	{
		for (FSpeedEffectRequest Request : SpeedEffectComp.ValueRequests)
		{
			if (Request.Value > 0.f)
				return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SceneView::IsFullScreen())
        	return EHazeNetworkDeactivation::DeactivateLocal;

		if (SpeedEffectComp.Value <= 0.f)
        	return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SpeedEffectNiagaraComp.Activate();
		SpeedEffectNiagaraComp.SetFloatParameter(n"Alpha", 0.f);

		PostProcessComp.SpeedShimmer = SpeedEffectComp.Value * SpeedShimmerScale;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SpeedEffectNiagaraComp.Deactivate();

		PostProcessComp.SpeedShimmer = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		SpeedEffectComp.Value = 0.f;
		SpeedEffectNiagaraComp.Deactivate();

		PostProcessComp.SpeedShimmer = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdateEffects();
	}

	void UpdateEffectValue(float DeltaTime)
	{
		FSpeedEffectRequest TargetRequest = GetHighestRequest();

		float TargetValue = FMath::Min(TargetRequest.Value, MaximumValue);
		if (TargetRequest.bSnap)
			SpeedEffectComp.Value = TargetValue;
		else
		{
			float InterpSpeed = TargetValue > SpeedEffectComp.Value ? SpeedEffectValueInterpSpeedUpwards : SpeedEffectValueInterpSpeedDownwards;
			SpeedEffectComp.Value = FMath::FInterpConstantTo(SpeedEffectComp.Value, TargetValue, DeltaTime, InterpSpeed);

		}

#if EDITOR
		if(IsDebugActive())
			PrintToScreenScaled("" + SpeedEffectComp.Value, Scale = 1.8f);
#endif
	}

	void UpdateEffects()
	{
		UpdateNiagaraEffect();
		UpdateSpeedShimmer();
	}

	void UpdateNiagaraEffect()
	{
		SpeedEffectNiagaraComp.SetWorldLocation(Player.ViewLocation);		
		SpeedEffectNiagaraComp.SetWorldRotation(NiagaraRotation);

		SpeedEffectNiagaraComp.SetFloatParameter(n"Alpha", SpeedEffectComp.Value);		
	}  

	void UpdateSpeedShimmer()
	{
		float SpeedShimmerValue = SpeedEffectComp.Value * SpeedShimmerScale;

		// FVector Direction = Player.ActorVelocity.GetClampedToMaxSize(1.f);
		// SpeedShimmerValue *= Player.ViewRotation.ForwardVector.DotProduct(Direction);

		PostProcessComp.SpeedShimmer = SpeedShimmerValue;
	}

	FRotator GetTargetNiagaraEffectRotation() property
	{
		FRotator TargetRotation = FRotator::MakeFromX(-Player.ActorVelocity);
		if (Player.ActorVelocity.IsNearlyZero())
		{
			TargetRotation = FRotator::MakeFromX(-Player.ActorForwardVector);
		}

		return TargetRotation;
	} 

	FSpeedEffectRequest GetHighestRequest() property
	{
		FSpeedEffectRequest CurrentRequest();

		for (FSpeedEffectRequest Request : SpeedEffectComp.ValueRequests)
		{
			if (Request.Value > CurrentRequest.Value)
			{
				CurrentRequest = Request;
			}
		}

		return CurrentRequest;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		return SpeedEffectDebugString;
	}
}