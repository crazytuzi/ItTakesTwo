
struct FTestCopyStructReference
{
	FVector InteralRelativeLocation;
	float TraceLength;
	FVector From;
	FVector To;

	FHitResult Ground;
	bool bIsValid;
};

void TestStructCopyOutRef(FTestCopyStructReference& D)
{
	FTestCopyStructReference A;
	A.bIsValid = true;

	D = A;
}

void TestStructCopyReference()
{
	FTestCopyStructReference A;
	A.bIsValid = true;

	FTestCopyStructReference& ACopy = A;

	FTestCopyStructReference B = ACopy;
	FTestCopyStructReference C;
	C = ACopy;

	ensure(B.bIsValid);
	ensure(C.bIsValid);

	FTestCopyStructReference D;
	TestStructCopyOutRef(D);

	ensure(D.bIsValid);
}