//import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;
//
//// Most of the pendulum gravity is handled by as Physics constraint on the BP layer. 
//
//UCLASS()
//class UQueenPendulumCapability : UQueenBaseCapability 
//{
//	UPROPERTY()
//	FPendulumPIDController PID;
//
//	UFUNCTION(BlueprintOverride)
//	void Setup(const FCapabilitySetupParams& SetupParams)
//	{
//		Super::Setup(SetupParams);
////		PID.InitErrorThreshold();
//	}
//
// 	UFUNCTION(BlueprintOverride)
//	void TickActive(float DeltaSeconds)
//	{
//		const float UpDOTUp = Queen.GetActorUpVector().DotProduct(FVector::UpVector);
//		const float PendulumAngleError = FMath::Sin(FMath::Acos(FMath::Max(UpDOTUp, 0.f)));
//		const float WorldGravity = -982.f;
//
//		// Stabilize quicker by applying extra gravity.
//		float PendulumGravityMag = WorldGravity;
//		PendulumGravityMag *= PendulumAngleError;
//		PendulumGravityMag *= Settings.Movement.PendulumGravityMultiplier;
//
////		// Prevent pendulum from swinging to wildly.
////		PID.Update(PendulumAngleError, DeltaSeconds);
////		PendulumGravityMag += (WorldGravity * FMath::Max(PID.Params.Value, 0.f));
//
//		Queen.Mesh.AddForce(
//			FVector(0.f, 0.f, PendulumGravityMag),
//			NAME_None,
//			bAccelChange = true
//		);
//	}
//
//}
//
//struct FPendulumPIDController
//{
//	/** Settings */
//	UPROPERTY()
//	FPendulumPIDSettings Settings;
//
//	/** Runtime variables */
//	UPROPERTY(NotEditable, BlueprintReadOnly)
//	FPendulumPIDParameters Params;
//
//	void InitErrorThreshold()
//	{
//		float SafeErrorThreshold = FMath::Abs(Settings.ErrorThreshold_DEG);
//		SafeErrorThreshold = FMath::Min(SafeErrorThreshold, 90.f);
//		SafeErrorThreshold = FMath::DegreesToRadians(SafeErrorThreshold);
//		SafeErrorThreshold = FMath::Sin(SafeErrorThreshold);
//		Params.ErrorThreshold = SafeErrorThreshold;
////		Print(
////			"PendThreshold: " 
////			+ Settings.ErrorThreshold_DEG 
////			+ " | Converted: " 
////			+ SafeErrorThreshold
////		);
//	}
//
//	void Update(const float Error, const float Dt) 
//	{
//		if (Error > Params.ErrorThreshold)
//		{
//			// Derivative 
//			const double TimeStep = Params.Dt_Prev + Params.Dt_PrevPrev;	// ~ 2*Dt
//			const double DeltaError = Error - Params.Error_PrevPrev;
//			double Derivative = TimeStep != 0.f ? (DeltaError / TimeStep) : 0.f;
//
//			// Integral	
//			// (we lerp in order to reduce spikes and limit how far back we remember)
//			Params.IntegralError = FMath::LerpStable(
//				Params.IntegralError,
//				Error, 
//				Settings.IntegralTimeConstant
//			);
//
//			const float P = Error * Settings.KError_Proportional;
//			const float I = Params.IntegralError * Settings.KError_Integral;
//			const float D = Derivative * Settings.KError_Derivative;
//
////			Print("PID P: " + P);
////			Print("PID I: " + I);
////			Print("PID D: " + D);
//
//			Params.Value = P+I+D;
//		}
//		else 
//		{
//			// Reset integral memory 
//			Params.IntegralError = 0.f;
//			Params.Value = 0.f;
//		}
//
////		Print("PID Value: " + Params.Value);
//
//		// rotate derivative buffers
//		Params.Error_PrevPrev = Params.Error_Prev;
//		Params.Error_Prev = Error;
//		Params.Dt_PrevPrev = Params.Dt_Prev;
//		Params.Dt_Prev = Dt;
//	}
//};
//
///** Editor Settings */
//struct FPendulumPIDSettings
//{
//	/** PID forces will only activate when crossing this threshold. */
//	UPROPERTY()
//	float ErrorThreshold_DEG = 1.f;
//
//	/** Error gain multiplier  */
//	UPROPERTY()
//	float KError_Proportional = 15.f;
//
//	/** Integral Error gain multiplier  */
//	UPROPERTY()
//	float KError_Integral = 10.f;
//
//	/** Derivative Error gain multiplier  */
//	UPROPERTY()
//	float KError_Derivative = 50.f;		 
//
//	/** Time Constant integral: How much of the integral history
//	    Should be discarded (percentage wise) every frame.
//		Range = [0...1] */
//	UPROPERTY()
//	float IntegralTimeConstant = 0.8f;
//};
//
///** Container for parameters saved during runtime */
//struct FPendulumPIDParameters
//{
//	// Editor degree value converted to radians
//	UPROPERTY()
//	float ErrorThreshold = 0.f;
//
//	/** Last */
//	UPROPERTY()
//	float Dt_Prev = 0.f;
//
//	/** Second to last  */
//	UPROPERTY()
//	float Dt_PrevPrev = 0.f;
//
//	/** Last */
//	UPROPERTY()
//	float Error_Prev = 0.f;
//
//	/** Second to last  */
//	UPROPERTY()
//	float Error_PrevPrev = 0.f;
//
//	/** Error memory, normalized */
//	UPROPERTY()
//	float IntegralError = 0.f;
//
//	/* Current PID value */
//	UPROPERTY()
//	float Value = 0.f;
//};