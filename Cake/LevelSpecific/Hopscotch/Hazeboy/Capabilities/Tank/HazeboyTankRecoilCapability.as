import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyTank;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager;
import Rice.Math.MathStatics;

class UHazeboyTankRecoilCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 105;

	AHazeboyTank Tank;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Tank = Cast<AHazeboyTank>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HazeboyGameIsActive())
			return EHazeNetworkActivation::DontActivate;

		if (Tank.OwningPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (Tank.Recoil.IsNearlyZero() && Tank.RecoilVelocity.IsNearlyZero())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!HazeboyGameIsActive())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Tank.OwningPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Tank.Recoil.IsNearlyZero() && Tank.RecoilVelocity.IsNearlyZero())
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Tank.Recoil = FVector::ZeroVector;
		Tank.RecoilVelocity = FVector::ZeroVector;
		Tank.RecoilRoot.RelativeTransform = FTransform();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector PrevRecoil = Tank.Recoil;

		Tank.RecoilVelocity -= Tank.Recoil.GetSafeNormal() * 10.f * DeltaTime;
		Tank.RecoilVelocity -= Tank.RecoilVelocity * 1.2f * DeltaTime;

		Tank.Recoil += Tank.RecoilVelocity * DeltaTime;

		if (Tank.Recoil.DotProduct(PrevRecoil) < 0.f)
		{
			Tank.RecoilVelocity *= 0.5f;
			if (Tank.RecoilVelocity.Size() < 0.4f)
			{
				Tank.RecoilVelocity = FVector::ZeroVector;
				Tank.Recoil = FVector::ZeroVector;
			}
		}

		// We want to rotate around one of the treads, so calculate _virtual_ transform, I guess,
		// of where the recoil root _should_ be if it was rotating around some other origin
		FVector RotateOrigin = Tank.Recoil.CrossProduct(FVector::UpVector);
		RotateOrigin.Normalize();
		RotateOrigin *= 100.f;

		FTransform OriginTransform;
		OriginTransform.Location = RotateOrigin;
		OriginTransform.Rotation = FQuat(Tank.Recoil.GetSafeNormal(), Tank.Recoil.Size());

		FTransform RootTransform;
		RootTransform.Location = -RotateOrigin;

		FTransform FinalTransform = RootTransform * OriginTransform;
		Tank.RecoilRoot.RelativeTransform = FinalTransform;
	}
}