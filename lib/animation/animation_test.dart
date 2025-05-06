part of 'animation_progress.dart';

class AnimationTest {
  bool _test = false;

  int _testNumber = 0;

  double _testProgress = 0;

  double progress(double progress) {
    if (!_test) {
      return progress;
    }
    return _testProgress;
  }

  Widget testWidget({String? name, Function()? setState}) {
    if (!kDebugMode) {
      return Container();
    }

    return Container(
      width: 120,
      height: 56,
      decoration: const BoxDecoration(color: Colors.white54),
      child: Column(
        children: [
          _headerView(name ?? "default"),
          const SizedBox(height: 2),
          _mainView(setState: setState),
        ],
      ),
    );
  }

  Widget _headerView(String name) {
    return Row(
      children: [
        Container(
          alignment: Alignment.centerLeft,
          height: 22,
          width: 120,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(color: Colors.white),
          child: Text(
            "$name: ${_testProgress.toInt()}",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }

  Widget _mainView({Function()? setState}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () {
            if (!_test) {
              return;
            }
            _testProgress = max(0, _testProgress - _testNumber);
            setState?.call();
          },
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                )
              ],
            ),
            child: const Icon(
              Icons.remove,
              color: Colors.black,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            switch (_testNumber) {
              case 0:
                _testNumber = 1;
                _test = true;
                break;
              case 1:
                _testNumber = 5;
                break;
              case 5:
                _testNumber = 100;
                break;
              case 100:
                _testNumber = 0;
                _test = false;
                break;
            }
            setState?.call();
          },
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                )
              ],
            ),
            child: Text(
              _testNumber.toString(),
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            if (!_test) {
              return;
            }
            _testProgress = min(100, _testProgress + _testNumber);
            setState?.call();
          },
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                )
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
